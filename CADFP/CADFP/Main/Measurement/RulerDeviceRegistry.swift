//
//  RulerDeviceRegistry.swift
//  CADFP
//
//  Created by Codex on 2026/4/10.
//

import Foundation
import UIKit

enum RulerDeviceRegistry {
    static func currentProfile(screen: UIScreen = .main) -> RulerDisplayProfile? {
        profile(for: hardwareIdentifier(), nativeScale: Double(screen.nativeScale))
    }

    static func hardwareIdentifier() -> String {
        #if targetEnvironment(simulator)
        if let simulatorIdentifier = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulatorIdentifier
        }
        #endif

        var systemInfo = utsname()
        uname(&systemInfo)

        return withUnsafePointer(to: &systemInfo.machine) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: 1) { machinePointer in
                String(cString: machinePointer)
            }
        }
    }

    static func profile(for identifier: String, nativeScale: Double) -> RulerDisplayProfile? {
        guard let ppi = pixelsPerInchByIdentifier[identifier] else {
            return nil
        }

        return RulerDisplayProfile(
            hardwareIdentifier: identifier,
            ppi: ppi,
            nativeScale: nativeScale
        )
    }

    private static let pixelsPerInchByIdentifier: [String: Double] = [
        "iPhone10,1": 326,
        "iPhone10,2": 401,
        "iPhone10,3": 458,
        "iPhone10,4": 326,
        "iPhone10,5": 401,
        "iPhone10,6": 458,
        "iPhone11,2": 458,
        "iPhone11,4": 458,
        "iPhone11,6": 458,
        "iPhone11,8": 326,
        "iPhone12,1": 326,
        "iPhone12,3": 458,
        "iPhone12,5": 458,
        "iPhone13,1": 476,
        "iPhone13,2": 460,
        "iPhone13,3": 460,
        "iPhone13,4": 458,
        "iPhone14,2": 460,
        "iPhone14,3": 458,
        "iPhone14,4": 476,
        "iPhone14,5": 460,
        "iPhone14,6": 326,
        "iPhone14,7": 460,
        "iPhone14,8": 458,
        "iPhone15,2": 460,
        "iPhone15,3": 460,
        "iPhone15,4": 460,
        "iPhone15,5": 460,
        "iPhone16,1": 460,
        "iPhone16,2": 460,
        "iPhone17,1": 460,
        "iPhone17,2": 460,
        "iPhone17,3": 460,
        "iPhone17,4": 460,
        "iPhone17,5": 460,
    ]
}
