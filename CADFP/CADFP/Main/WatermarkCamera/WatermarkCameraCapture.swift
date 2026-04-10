//
//  WatermarkCameraCapture.swift
//  CADFP
//
//  Created by Codex on 2026/4/10.
//

@preconcurrency import AVFoundation
import Combine
import SwiftUI
import UIKit

enum CameraAuthorizationState {
    case unknown
    case authorized
    case denied
    case restricted
    case unavailable
}

enum CameraCaptureError: LocalizedError {
    case cameraUnavailable
    case permissionDenied
    case invalidPhoto

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "当前设备不可用相机，已切换为模拟预览。"
        case .permissionDenied:
            return "请在系统设置中允许访问相机。"
        case .invalidPhoto:
            return "拍照结果解析失败，请重试。"
        }
    }
}

enum CameraCaptureMode {
    case previewOnly
    case photoCapture

    var attachesPhotoOutput: Bool {
        self == .photoCapture
    }

    var sessionPreset: AVCaptureSession.Preset {
        switch self {
        case .previewOnly:
            return .high
        case .photoCapture:
            return .photo
        }
    }
}

final class CameraCaptureService: NSObject, ObservableObject {
    @Published private(set) var authorizationState: CameraAuthorizationState = .unknown
    @Published private(set) var isSessionConfigured = false

    let session = AVCaptureSession()

    private let mode: CameraCaptureMode
    private let sessionQueue = DispatchQueue(label: "pdia.cadfp.watermark-camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var didConfigureSession = false
    private var configurationTask: Task<Bool, Never>?
    private var captureContinuation: CheckedContinuation<UIImage, Error>?

    init(mode: CameraCaptureMode = .photoCapture) {
        self.mode = mode
        super.init()
    }

    @MainActor
    func prepareSession() async {
        guard isCameraAvailable else {
            authorizationState = .unavailable
            isSessionConfigured = false
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            authorizationState = .authorized
            await applyConfigurationIfNeeded()
        case .notDetermined:
            let granted = await requestCameraPermission()
            authorizationState = granted ? .authorized : .denied

            if granted {
                await applyConfigurationIfNeeded()
            }
        case .denied:
            authorizationState = .denied
        case .restricted:
            authorizationState = .restricted
        @unknown default:
            authorizationState = .denied
        }
    }

    @MainActor
    func prewarmSessionIfAuthorized() async {
        guard isCameraAvailable else {
            authorizationState = .unavailable
            isSessionConfigured = false
            return
        }

        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            return
        }

        authorizationState = .authorized
        await applyConfigurationIfNeeded()
    }

    @MainActor
    func startSession() {
        guard authorizationState == .authorized, isSessionConfigured else { return }

        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    @MainActor
    func stopSession() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func capturePhoto() async throws -> UIImage {
        guard mode.attachesPhotoOutput else {
            throw CameraCaptureError.cameraUnavailable
        }

        switch authorizationState {
        case .authorized:
            return try await withCheckedThrowingContinuation { continuation in
                captureContinuation = continuation
                sessionQueue.async {
                    let settings: AVCapturePhotoSettings
                    if self.photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
                        settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                    } else {
                        settings = AVCapturePhotoSettings()
                    }

                    settings.flashMode = .off
                    self.photoOutput.capturePhoto(with: settings, delegate: self)
                }
            }
        case .unavailable:
            return WatermarkPhotoComposer.placeholderPhoto()
        case .denied, .restricted:
            throw CameraCaptureError.permissionDenied
        case .unknown:
            throw CameraCaptureError.cameraUnavailable
        }
    }

    @MainActor
    private func applyConfigurationIfNeeded() async {
        let success = await ensureSessionConfigured()
        isSessionConfigured = success

        if !success {
            authorizationState = .unavailable
        }
    }

    @MainActor
    private func ensureSessionConfigured() async -> Bool {
        if didConfigureSession {
            return true
        }

        if let configurationTask {
            return await configurationTask.value
        }

        let configurationTask = Task { [weak self] in
            guard let self else {
                return false
            }

            return await withCheckedContinuation { continuation in
                self.sessionQueue.async {
                    self.session.beginConfiguration()
                    self.session.sessionPreset = self.mode.sessionPreset

                    defer {
                        self.session.commitConfiguration()
                    }

                    guard
                        let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                        let input = try? AVCaptureDeviceInput(device: camera),
                        self.session.canAddInput(input)
                    else {
                        continuation.resume(returning: false)
                        return
                    }

                    self.session.inputs.forEach { self.session.removeInput($0) }
                    self.session.outputs.forEach { self.session.removeOutput($0) }

                    self.session.addInput(input)

                    guard self.mode.attachesPhotoOutput else {
                        self.didConfigureSession = true
                        continuation.resume(returning: true)
                        return
                    }

                    guard self.session.canAddOutput(self.photoOutput) else {
                        continuation.resume(returning: false)
                        return
                    }

                    self.session.addOutput(self.photoOutput)
                    self.didConfigureSession = true
                    continuation.resume(returning: true)
                }
            }
        }

        self.configurationTask = configurationTask
        let success = await configurationTask.value
        self.configurationTask = nil
        return success
    }

    private var isCameraAvailable: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil
    }

    @MainActor
    private func requestCameraPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}

extension CameraCaptureService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            captureContinuation?.resume(throwing: error)
            captureContinuation = nil
            return
        }

        guard
            let data = photo.fileDataRepresentation(),
            let image = UIImage(data: data)
        else {
            captureContinuation?.resume(throwing: CameraCaptureError.invalidPhoto)
            captureContinuation = nil
            return
        }

        captureContinuation?.resume(returning: image)
        captureContinuation = nil
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        uiView.previewLayer.session = session
    }
}

final class PreviewContainerView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
