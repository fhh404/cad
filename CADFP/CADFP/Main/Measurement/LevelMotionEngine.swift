//
//  LevelMotionEngine.swift
//  CADFP
//
//  Created by Codex on 2026/4/11.
//

import CoreMotion
import Combine
import Foundation
import UIKit

@MainActor
final class LevelMotionEngine: ObservableObject {
    @Published private(set) var sample: LevelMotionSample = .flat
    @Published private(set) var orientation: UIDeviceOrientation = .portrait
    @Published private(set) var isMotionAvailable = true

    private let motionManager: CMMotionManager
    private let filterStrength: Double
    private var isRunning = false
    private var orientationObserver: NSObjectProtocol?

    init(
        motionManager: CMMotionManager = CMMotionManager(),
        filterStrength: Double = 0.22
    ) {
        self.motionManager = motionManager
        self.filterStrength = filterStrength
        self.orientation = LevelGeometry.displayOrientation(
            from: UIDevice.current.orientation,
            fallback: .portrait
        )
    }

    deinit {
        motionManager.stopDeviceMotionUpdates()
        if let orientationObserver {
            NotificationCenter.default.removeObserver(orientationObserver)
        }
        Task { @MainActor in
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
    }

    func start() {
        guard !isRunning else {
            return
        }

        isRunning = true
        orientation = LevelGeometry.displayOrientation(
            from: UIDevice.current.orientation,
            fallback: orientation
        )
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        orientationObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else {
                return
            }

            Task { @MainActor in
                self.updateOrientation(UIDevice.current.orientation)
            }
        }

        guard motionManager.isDeviceMotionAvailable else {
            isMotionAvailable = false
            return
        }

        isMotionAvailable = true
        motionManager.deviceMotionUpdateInterval = 1 / 30
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else {
                return
            }

            Task { @MainActor in
                self.apply(gravity: motion.gravity)
            }
        }
    }

    func stop() {
        guard isRunning else {
            return
        }

        isRunning = false
        motionManager.stopDeviceMotionUpdates()
        if let orientationObserver {
            NotificationCenter.default.removeObserver(orientationObserver)
            self.orientationObserver = nil
        }
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    private func updateOrientation(_ newOrientation: UIDeviceOrientation) {
        orientation = LevelGeometry.displayOrientation(from: newOrientation, fallback: orientation)
    }

    private func apply(gravity: CMAcceleration) {
        let nextSample = LevelMotionSample(
            gravityX: filteredValue(current: sample.gravityX, next: gravity.x),
            gravityY: filteredValue(current: sample.gravityY, next: gravity.y),
            gravityZ: filteredValue(current: sample.gravityZ, next: gravity.z)
        )

        if nextSample != sample {
            sample = nextSample
        }
    }

    private func filteredValue(current: Double, next: Double) -> Double {
        current + (next - current) * filterStrength
    }
}
