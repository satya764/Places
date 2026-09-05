//
//  PlacesMapView.swift
//  Places
//
//  Created by SATYA on 9/5/26.
//

import SwiftUI
import MapKit

// SwiftUI map screen: all saved places as pins + the user's location.
// Pushed from the UIKit grid via UIHostingController (SwiftUI/UIKit interop).
struct PlacesMapView: View {
    let places: [Place]
    @StateObject private var location = LocationManager()
    @State private var camera: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $camera) {
            UserAnnotation()
            ForEach(places) { place in
                Marker(
                    place.title,
                    coordinate: CLLocationCoordinate2D(
                        latitude: place.latitude,
                        longitude: place.longitude
                    )
                )
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { location.request() }
    }
}
