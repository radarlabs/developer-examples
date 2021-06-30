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

enum TripState {
    case uninitialized, loading, error, arrived
}

final class TripManager: ObservableObject {
    @Published var tripState: TripState = .uninitialized
    @Published var events: [RadarEvent]? = nil
    
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
            } else {
                self.tripState = .error
                self.events = nil
            }
        }
    }
    
    func setupTrip(completionHandler: @escaping RadarTripCompletionHandler) {
        // set up a trip
        let number = Int.random(in: 0...1000)
        let tripOptions = RadarTripOptions(externalId: "curbside-trip-\(number)")
        tripOptions.destinationGeofenceTag = "curbside-stores"
        tripOptions.destinationGeofenceExternalId = "my-store-1"
        tripOptions.mode = .car
        tripOptions.metadata = [
            "Customer Name": "Jon Hammburglar",
            "Car Model": "Hamburglar Mobile",
            "Phone": "TEST_PHONE_NUMBER"
        ]
        Radar.startTrip(options: tripOptions, completionHandler: completionHandler)
    }
    
    func simulateTrip() {
        if self.tripState == .loading {
            return
        }
        
        self.tripState = .loading
        setupTrip { status in
            let numberOfSteps: Int32 = 8
            var currentStep: Int32 = 0
            if status == RadarStatus.success {
                Radar.mockTracking(
                    origin: CLLocation(
                        latitude: CLLocationDegrees(40.69770571883561),
                        longitude: CLLocationDegrees(-73.96773934364319)),
                    destination: CLLocation(
                        latitude: CLLocationDegrees(40.70441607862966),
                        longitude: CLLocationDegrees(-73.98654699325562)),
                    mode: RadarRouteMode.car,
                    steps: numberOfSteps,
                    interval: TimeInterval(1)) { status, location, events, user in
                        // handle error case
                        if status != RadarStatus.success {
                            self.tripState = .error
                            return
                        }

                        // update trip step
                        self.events = events
                        
                        // check if trip is done
                        currentStep += 1
                        if currentStep == numberOfSteps {
                            self.tripState = .arrived
                            Radar.completeTrip()
                        }
                    }
            } else {
                self.tripState = .error
            }
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
            
            Button(action: { self.tripManager.simulateTrip() }) {
                switch self.tripManager.tripState {
                case .uninitialized:
                    Text("Start Trip 🏃‍♂️")
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
