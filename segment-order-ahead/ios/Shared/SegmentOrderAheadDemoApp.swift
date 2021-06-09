//
//  SegmentOrderAheadDemoApp.swift
//  Shared
//
//  Created by Jeff Kao on 6/8/21.
//

import SwiftUI
import RadarSDK
import Segment

@main
struct SegmentOrderAheadDemoApp: App {
    
    let locationManager = CLLocationManager()
    
    init() {
        let userId = "hamburglar"
        
        // initialize the Radar SDK and user
        Radar.initialize(publishableKey: "PUBLISHABLE_KEY")
        Radar.setUserId(userId)
        
        // initialize Segment and user
        let configuration = AnalyticsConfiguration(writeKey: "SEGMENT_KEY")
        Analytics.setup(with: configuration)
        Analytics.shared().identify(userId, traits: ["name": "Jon Hammburglar"])
        
        // request location permission
        let status = self.locationManager.authorizationStatus
        if status == .notDetermined {
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            DemoView()
        }
    }
    
}
