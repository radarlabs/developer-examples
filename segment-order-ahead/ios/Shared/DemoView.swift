//
//  ContentView.swift
//  Shared
//
//  Created by Jeff Kao on 6/8/21.
//

import SwiftUI
import MapKit
import Foundation
import RadarSDK
import Segment

enum TripState {
    case uninitialized, loading, error, started, approaching, arrived
}

final class TripManager: ObservableObject {
    @Published var tripState: TripState = .uninitialized
    @Published var events: [RadarEvent]? = nil
    
    func sendEventsToSegment(events: [RadarEvent]?) {
        for event in events ?? [] {
            let eventType = RadarEvent.string(for: event.type) ?? "unknown"
            let tripStatus = event.trip?.status ?? RadarTripStatus.unknown;
            
            var payload: [String: Any] = [String: String]()
            switch tripStatus {
            case RadarTripStatus.started:
                payload = [
                    "tripStatus": "started",
                    "tripId": event.trip?._id,
                    "tripMetadata": event.trip?.metadata
                ]
            case RadarTripStatus.approaching:
                payload = [
                    "tripStatus": "approaching",
                    "tripId": event.trip?._id,
                    "tripMetadata": event.trip?.metadata
                ]
            case RadarTripStatus.arrived:
                payload = [
                    "tripStatus": "arrived",
                    "tripId": event.trip?._id,
                    "tripMetadata": event.trip?.metadata
                ]
            default:
                break
            }
            
            Analytics
                .shared()
                .track(eventType, properties: payload)
        }
    }
    
    
    func simulateLocationUpdate(latitude: Double, longitude: Double, nextTripState: TripState) {
        let location = CLLocation(
            latitude: CLLocationDegrees(latitude),
            longitude: CLLocationDegrees(longitude)
        )
        
        self.tripState = .loading
        
        Radar.trackOnce(
            location: location
        ) { (status, location, events, user) in
            if status == RadarStatus.success {
                self.tripState = nextTripState
                self.events = events
                self.sendEventsToSegment(events: events)
            } else {
                self.tripState = .error
                self.events = nil
            }
        }
    }
    
    func setupTrip(completionHandler: @escaping RadarTripCompletionHandler) {
        // set up a trip
        let tripOptions = RadarTripOptions(externalId: "my-first-burger-pickup")
        tripOptions.destinationGeofenceTag = "curbside-stores"
        tripOptions.destinationGeofenceExternalId = "my-store-1"
        tripOptions.mode = .car
        tripOptions.metadata = [
            "Customer Name": "Jon Hammburglar",
            "Car Model": "Hamburglar Mobile",
            "Phone": "5551234567"
        ]
        Radar.startTrip(options: tripOptions, completionHandler: completionHandler)
    }
    
    func toggleTripState() {
        switch self.tripState {
        case .uninitialized:
            setupTrip() { (status) in
                if status == RadarStatus.success {
                    self.simulateLocationUpdate(
                        latitude: 40.69770571883561,
                        longitude:  -73.96773934364319,
                        nextTripState: .started
                    )
                } else {
                    self.tripState = .error
                }
            }
        case .started:
            simulateLocationUpdate(
                latitude: 40.70221190166743,
                longitude: -73.98119330406189,
                nextTripState: .approaching
            )
        case .approaching:
            simulateLocationUpdate(
                latitude: 40.70441607862966,
                longitude: -73.98654699325562,
                nextTripState: .arrived
            )
        case .loading:
            break
        case .error:
            break
        case .arrived:
            break
        }
    }
}

struct DemoView: View {
    
    @StateObject private var tripManager = TripManager()
    
    var body: some View {
        VStack {
            Text("Order-Ahead Demo")
                .font(.title)
         
            if let events = self.tripManager.events {
                ForEach(events, id: \.self._id) { event in
                    Text("\(event._id) \(RadarEvent.string(for: event.type) ?? "unknown")")
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                        .padding()
                }
            } else {
                Text("debug info appears here")
                    .font(.caption)
                    .padding()
            }
            
            Button(action: { self.tripManager.toggleTripState() }) {
                switch self.tripManager.tripState {
                case .uninitialized:
                    Text("Start Trip 🏃‍♂️")
                case .started:
                    Text("Trip Started 🏁")
                case .approaching:
                    Text("Approaching 🚗")
                case .arrived:
                    Text("Arrived 🍔")
                case .loading:
                    Text("Loading ⏳")
                case .error:
                    Text("Error 🦨")
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(Color.white)
            .clipShape(Capsule())
        }
    }
}

struct DemoView_Previews: PreviewProvider {
    static var previews: some View {
        DemoView()
    }
}
