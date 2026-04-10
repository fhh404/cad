//
//  WatermarkLocationService.swift
//  CADFP
//
//  Created by Codex on 2026/4/10.
//

import CoreLocation
import Foundation

@MainActor
final class WatermarkLocationService: NSObject {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var continuation: CheckedContinuation<String, Never>?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func refreshCurrentAddress() async -> String {
        guard CLLocationManager.locationServicesEnabled() else {
            return WatermarkDraft.unavailableLocationText
        }

        let status = locationManager.authorizationStatus
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return await requestLocation()
        case .notDetermined:
            return await requestAuthorizationAndLocation()
        case .restricted, .denied:
            return WatermarkDraft.unavailableLocationText
        @unknown default:
            return WatermarkDraft.unavailableLocationText
        }
    }

    private func requestAuthorizationAndLocation() async -> String {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            locationManager.requestWhenInUseAuthorization()
        }
    }

    private func requestLocation() async -> String {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            locationManager.requestLocation()
        }
    }

    private func resolve(with address: String) {
        continuation?.resume(returning: address)
        continuation = nil
    }

    private func reverseGeocodeAddress(from location: CLLocation) async -> String {
        await withCheckedContinuation { continuation in
            geocoder.reverseGeocodeLocation(location, preferredLocale: Locale(identifier: "zh_CN")) { placemarks, _ in
                let address = placemarks?
                    .compactMap { placemark in
                        Self.formattedAddress(from: placemark)
                    }
                    .first
                    ?? WatermarkDraft.unavailableLocationText
                continuation.resume(returning: address)
            }
        }
    }

    nonisolated private static func formattedAddress(from placemark: CLPlacemark) -> String? {
        let rawParts = [
            placemark.locality,
            placemark.subAdministrativeArea,
            placemark.subLocality,
            placemark.thoroughfare
        ]

        var seen = Set<String>()
        let parts = rawParts.compactMap { item -> String? in
            guard let value = item?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
                return nil
            }

            guard !seen.contains(value) else {
                return nil
            }

            seen.insert(value)
            return value
        }

        guard !parts.isEmpty else {
            return nil
        }

        return parts.joined()
    }
}

extension WatermarkLocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                guard continuation != nil else { return }
                locationManager.requestLocation()
            case .restricted, .denied:
                resolve(with: WatermarkDraft.unavailableLocationText)
            case .notDetermined:
                break
            @unknown default:
                resolve(with: WatermarkDraft.unavailableLocationText)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            Task { @MainActor in
                resolve(with: WatermarkDraft.unavailableLocationText)
            }
            return
        }

        Task { @MainActor in
            let address = await reverseGeocodeAddress(from: location)
            resolve(with: address)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let locationError = error as? CLError, locationError.code == .locationUnknown {
            return
        }

        Task { @MainActor in
            resolve(with: WatermarkDraft.unavailableLocationText)
        }
    }
}
