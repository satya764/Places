//
//  LocationManager.swift
//  Places
//
//  Created by SATYA on 9/5/26.
//

import Foundation
import CoreLocation
import Combine
import SwiftUI

// requests permission to show the user's location on the map.
@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var authorized = false

    override init() {
        super.init()
        manager.delegate = self
    }

    func request() {
        manager.requestWhenInUseAuthorization()
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            self.authorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
        }
    }
}
