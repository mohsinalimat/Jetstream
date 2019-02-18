//
//  LocationTracker.swift
//  Jetstream
//
//  Created by Andrew Shepard on 1/21/15.
//  Copyright (c) 2015 Andrew Shepard. All rights reserved.
//

import Foundation
import CoreLocation
#if os(iOS)
import UIKit
#endif

public typealias LocationResult = Result<Location, Error>
public typealias Observer = (_ location: LocationResult) -> ()

enum LocationError: Error {
    case noData
    case other(Error)
}

public class LocationTracker: NSObject {
    
    private var lastResult: LocationResult = .failure(LocationError.noData)
    private var observers: [Observer] = []
    
    public var currentLocation: LocationResult {
        return self.lastResult
    }
    
    internal lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        #if os(iOS)
        locationManager.pausesLocationUpdatesAutomatically = true
        #endif
        return locationManager
    }()
    
    public override init() {
        super.init()
        
        #if os(iOS)
        NotificationCenter.default.addObserver(self, selector: #selector(LocationTracker.handleBackground(notification:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LocationTracker.handleForeground(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        #endif
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleBackground(notification: Notification) {
        stopUpdating()
    }
    
    @objc func handleForeground(notification: Notification) {
        startUpdating()
    }
    
    // MARK: - Public
    
    public func addLocationChangeObserver(_ observer: @escaping Observer) -> Void {
        observers.append(observer)
    }
    
    public func startUpdating() {
        locationManager.startUpdatingLocation()
    }
    
    public func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }
}

extension LocationTracker: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        #if os(iOS)
            switch status {
            case .authorizedWhenInUse:
                locationManager.startUpdatingLocation()
            default:
                locationManager.requestWhenInUseAuthorization()
            }
        #elseif os(OSX)
            locationManager.startUpdatingLocation()
        #endif
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let result = LocationResult.failure(LocationError.other(error))
        self.publishChange(with: result)
        self.lastResult = result
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let currentLocation = locations.first {
            if shouldUpdate(using: currentLocation) {
                
                let completion: ([CLPlacemark]?, Error?) -> () = { [weak self, currentLocation] (placemarks, error) in
                    guard let this = self else { return }
                    
                    if let placemark = placemarks?.first,
                        let city = placemark.locality,
                        let state = placemark.administrativeArea {
                        if this.shouldUpdate(using: currentLocation) {
                            let location = Location(location: currentLocation, city: city, state: state)
                            let result = LocationResult.success(location)
                            this.publishChange(with: result)
                            this.lastResult = result
                        }
                    } else {
                        let result = LocationResult.failure(LocationError.noData)
                        this.publishChange(with: result)
                        this.lastResult = result
                    }
                }
                
                CLGeocoder().reverseGeocodeLocation(currentLocation, completionHandler: completion)
            }
            
            // location hasn't changed significantly
        }
    }
}

extension LocationTracker {
    private func publishChange(with result: LocationResult) {
        if shouldUpdate(using: result) {
            observers.forEach { observer in
                observer(result)
            }
        }
    }
    
    private func shouldUpdate(using location: CLLocation) -> Bool {
        switch lastResult {
        case .success(let loc):
            return location.distance(from: loc.physical) > 100
        case .failure:
            return true
        }
    }
    
    private func shouldUpdate(using result: LocationResult) -> Bool {
        switch lastResult {
        case .success(let loc):
            return shouldUpdate(using: loc.physical)
        case .failure:
            return true
        }
    }
}

public struct Location: Equatable {
    public let physical: CLLocation
    public let city: String
    public let state: String
    
    public init(location physical: CLLocation, city: String, state: String) {
        self.physical = physical
        self.city = city
        self.state = state
    }
}

public func ==(lhs: Location, rhs: Location) -> Bool {
    return lhs.physical == rhs.physical
}
