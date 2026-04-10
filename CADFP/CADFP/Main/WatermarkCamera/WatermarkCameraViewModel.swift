//
//  WatermarkCameraViewModel.swift
//  CADFP
//
//  Created by Codex on 2026/4/10.
//

import Combine
import Foundation
import Photos
import SwiftUI
import UIKit

struct WatermarkCameraAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let opensSettings: Bool
}

@MainActor
final class WatermarkCameraViewModel: ObservableObject {
    @Published var draft = WatermarkDraft.seeded()
    @Published var editorDraft = WatermarkDraft.seeded()
    @Published var selectedStyle: WatermarkTemplateStyle = .classic
    @Published var overlayOffsetRatio: CGSize = .zero
    @Published var isEditingText = false
    @Published var isShowingStylePicker = false
    @Published var isCapturing = false
    @Published var alert: WatermarkCameraAlert?

    let captureService = CameraCaptureService()
    private let locationService = WatermarkLocationService()
    private var hasRequestedLocation = false
    private var isRefreshingLocation = false

    var overlayContent: WatermarkOverlayContent {
        selectedStyle.makeOverlayContent(from: draft)
    }

    var cameraNotice: String? {
        switch captureService.authorizationState {
        case .authorized:
            return nil
        case .unavailable:
            return "当前环境没有可用相机，已切换为模拟预览，拍照会导出示意图。"
        case .denied:
            return "相机权限已关闭，请到系统设置中开启后再拍照。"
        case .restricted:
            return "当前设备限制了相机访问。"
        case .unknown:
            return "正在准备相机..."
        }
    }

    func handleAppear() async {
        await captureService.prepareSession()
        captureService.startSession()
        await refreshLocationIfNeeded(force: !hasRequestedLocation)
    }

    func handleSceneActive() async {
        captureService.startSession()
        await refreshLocationIfNeeded(force: draft.address == WatermarkDraft.unavailableLocationText)
    }

    func handleDisappear() {
        captureService.stopSession()
    }

    func beginEditing() {
        isShowingStylePicker = false
        editorDraft = draft
        isEditingText = true
    }

    func beginStyleSelection() {
        isEditingText = false
        isShowingStylePicker = true
    }

    func dismissOverlays() {
        isEditingText = false
        isShowingStylePicker = false
    }

    func cancelEditing() {
        editorDraft = draft
        isEditingText = false
    }

    func confirmEditing() {
        draft.title = editorDraft.title
        draft.area = editorDraft.area
        draft.content = editorDraft.content
        draft.company = editorDraft.company
        isEditingText = false
    }

    func selectStyle(_ style: WatermarkTemplateStyle) {
        selectedStyle = style
        isShowingStylePicker = false
    }

    func interactiveOverlayOffsetRatio(for translation: CGSize, in previewSize: CGSize) -> CGSize {
        let proposedOffsetRatio = CGSize(
            width: overlayOffsetRatio.width + translation.width / max(previewSize.width, 1),
            height: overlayOffsetRatio.height + translation.height / max(previewSize.height, 1)
        )

        return selectedStyle.clampedOffsetRatio(
            in: previewSize,
            content: overlayContent,
            proposedOffsetRatio: proposedOffsetRatio,
            context: .preview
        )
    }

    func commitOverlayTranslation(_ translation: CGSize, in previewSize: CGSize) {
        overlayOffsetRatio = interactiveOverlayOffsetRatio(for: translation, in: previewSize)
    }

    func capture() async {
        guard !isCapturing else { return }

        isCapturing = true
        draft.captureDate = Date()

        do {
            let photo = try await captureService.capturePhoto()
            let result = WatermarkPhotoComposer.compose(
                photo: photo,
                draft: draft,
                style: selectedStyle,
                offsetRatio: overlayOffsetRatio
            )
            try await saveToPhotoLibrary(image: result)

            alert = WatermarkCameraAlert(
                title: "保存成功",
                message: "已将带水印的照片保存到系统相册。",
                opensSettings: false
            )
        } catch let error as CameraCaptureError {
            alert = WatermarkCameraAlert(
                title: "拍摄失败",
                message: error.errorDescription ?? "请稍后重试。",
                opensSettings: captureService.authorizationState == .denied
            )
        } catch let error as PhotoLibrarySaveError {
            alert = WatermarkCameraAlert(
                title: "保存失败",
                message: error.errorDescription ?? "请稍后重试。",
                opensSettings: error == .permissionDenied
            )
        } catch {
            alert = WatermarkCameraAlert(
                title: "拍摄失败",
                message: error.localizedDescription,
                opensSettings: false
            )
        }

        isCapturing = false
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func saveToPhotoLibrary(image: UIImage) async throws {
        let status = await requestPhotoAccessIfNeeded()
        guard status == .authorized || status == .limited else {
            throw PhotoLibrarySaveError.permissionDenied
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var placeholderIdentifier: String?

            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                placeholderIdentifier = request.placeholderForCreatedAsset?.localIdentifier
            }, completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard success, placeholderIdentifier != nil else {
                    continuation.resume(throwing: PhotoLibrarySaveError.unknown)
                    return
                }

                continuation.resume(returning: ())
            })
        }
    }

    private func requestPhotoAccessIfNeeded() async -> PHAuthorizationStatus {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch currentStatus {
        case .notDetermined:
            return await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        default:
            return currentStatus
        }
    }

    private func refreshLocationIfNeeded(force: Bool) async {
        guard force || !hasRequestedLocation else { return }
        guard !isRefreshingLocation else { return }

        hasRequestedLocation = true
        isRefreshingLocation = true

        let currentAddress = await locationService.refreshCurrentAddress()
        draft.address = currentAddress

        isRefreshingLocation = false
    }
}

enum PhotoLibrarySaveError: Error, Equatable, LocalizedError {
    case permissionDenied
    case unknown

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "请允许访问系统相册以保存照片。"
        case .unknown:
            return "保存到相册时出现异常，请重试。"
        }
    }
}
