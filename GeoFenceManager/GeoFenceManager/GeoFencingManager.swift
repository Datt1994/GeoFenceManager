//
//  GeoFencingManager.swift
//  GeoFenceManager
//
//  Created by datt on 29/11/18.
//  Copyright © 2018 datt. All rights reserved.
//

import UIKit
import CoreLocation

public enum GeoFenceStartMonitoringResult {
    case success
    case failure(String)
}

public struct GeoFenceManagerData : Decodable {
    let identifier : String
    let data : [String:AnyJSONType]?
    let lat : CLLocationDegrees
    let long : CLLocationDegrees
    let radius : Int
}

public class GeoFenceManager : NSObject {
    public static let shared = GeoFenceManager()
    
    /// Call When your current location enter some monitoring region
    public var didEnterRegionHandler: ((_ identifier:String,_ data:GeoFenceManagerData,_ region:CLRegion)->())?
    /// Call When your current location exit some monitoring region
    public var didExitRegionHandler: ((_ identifier:String,_ data:GeoFenceManagerData,_ region:CLRegion)->())?
    /// Call When your current location determine state form some monitoring region
    public var determineCurrentStateHandler: ((_ identifier:String,_ data:GeoFenceManagerData,_ region:CLRegion,_ state: CLRegionState)->())?
    /// Call When fail to start monitoring form some region
    public var monitoringDidFailForRegionHandler: ((_ identifier:String,_ data:GeoFenceManagerData,_ region:CLRegion,_ error: Error)->())?

    public let locationManager = CLLocationManager()
    fileprivate let UDGeoFencIDs = "GeoFencIDs"
    
    private override init() {
        super.init()
        startLocation()
    }
    
    /// Start Location Sevice and Authorization
    public func startLocation()  {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.startUpdatingLocation()
    }

    /// Using this this method you can start monitoring some region that provided by you with Parameters.
    ///
    /// When current location enter or exit any monitoring region following handler call, so use this handlers
    /// 1) didEnterRegionHandler
    /// 2) didExitRegionHandler
    /// 3) determineCurrentStateHandler
    /// 4) monitoringDidFailForRegionHandler
    ///
    /// You must call this method once for each region you want to monitor. If an existing region with the same identifier is already being monitored by the app, the old region is replaced by the new one.
    ///
    /// An app can register up to 20 regions at a time. In order to report region changes in a timely manner, the region monitoring service requires network connectivity.
    ///
    /// Regions with a radius between 1 and 400 meters work better on iPhone 4S or later devices. On these devices, an app can expect to receive the appropriate region entered or region exited notification within 3 to 5 minutes on average, if not sooner.
    /// - Parameters:
    ///   - radius: radius gives the distance in meters between the center and the region's boundary
    ///   - location: location gives the coordinates of center of the region
    ///   - identifier: unique identifier
    ///   - data: cutom data given when you anter or exit region
    ///   - completion: completion give you state, 'success' when GeoFence region Monitoring started successfully, 'failure' when some error occur with failure string
    public func startMonitoringGeoFence(radius: CLLocationDistance , location: CLLocationCoordinate2D , identifier: String , data: [String:AnyObject] , completion: ((GeoFenceStartMonitoringResult) -> ())? = nil) {
        // 1
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
//            showAlert(withTitle:"Error", message: "Geofencing is not supported on this device!")
            debugPrint("Geofencing is not supported on this device")
            completion?(.failure("Geofencing is not supported on this device"))
            return
        }
        // 2
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
//            showAlert(withTitle:"Warning", message: "Your geotification is saved but will only be activated once you grant Geotify permission to access the device location.")
            debugPrint("Your geotification is saved but will only be activated once you grant Geotify permission to access the device location.")
            completion?(.failure("Your geotification is saved but will only be activated once you grant Location permission to access the device location.To re-enable, please go to Settings and turn on Always Location Service for Geofencing."))
//            UIApplication.topViewController()?.present(showAlertView("Location Permission Denied", strAlertMessage: "To re-enable, please go to Settings and turn on Always Location Service for Geofencing."), animated: true){}
        }
        
        let geofenceRegion = CLCircularRegion(center: location, radius:  min(radius, locationManager.maximumRegionMonitoringDistance), identifier: identifier)
        
        if var dicIDs = UserDefaults.standard.dictionary(forKey: UDGeoFencIDs) as? [String : [String:Any]] {
            if dicIDs.count == 20 {
                debugPrint("Geofencing max Limit for Monitoring")
                completion?(.failure("Geofencing max Limit for Monitoring"))
                return
            }
//            if let _ = dicIDs[identifier] {
//                debugPrint("already added to Geofencing")
//                return true
//            }
            dicIDs[identifier] = ["identifier" : identifier , "data": data , "lat" : location.latitude , "long": location.longitude , "radius" : Int(radius)]
            UserDefaults.standard.set(dicIDs, forKey: UDGeoFencIDs)
        } else {
            UserDefaults.standard.set([identifier : ["identifier" : identifier , "data": data , "lat" : location.latitude , "long": location.longitude , "radius" : Int(radius)]], forKey: UDGeoFencIDs)
        }
        
        
        geofenceRegion.notifyOnExit = true
        geofenceRegion.notifyOnEntry = true
        locationManager.startMonitoring(for: geofenceRegion)
        completion?(.success)
        return
    }
    /// Stop all monitoring region used by GeoFenceManager class
    public func stopAllMonitoringGeoFence() {
        if let dicIDs = UserDefaults.standard.dictionary(forKey: UDGeoFencIDs) as? [String : [String:Any]] {
            for (key , value) in dicIDs {
                if let lat = value["lat"] as? CLLocationDegrees , let long = value["long"] as? CLLocationDegrees , let radius = value["radius"] as?  CLLocationDistance {
                    let geofenceRegion = CLCircularRegion(center: CLLocationCoordinate2DMake(lat, long), radius:  min(radius, locationManager.maximumRegionMonitoringDistance), identifier: key)
                    locationManager.stopMonitoring(for: geofenceRegion)
                }
            }
            UserDefaults.standard.removeObject(forKey: UDGeoFencIDs)
        }
    }
    /// Stop monitoring region for provided identifier
    /// - Parameter identifier: identifier associated with geofence Region
    public func stopMonitoringGeoFence(withID identifier: String) {
        if var dicIDs = UserDefaults.standard.dictionary(forKey: UDGeoFencIDs) as? [String : [String:Any]] , let matchDic = dicIDs[identifier] {
            if let lat = matchDic["lat"] as? CLLocationDegrees , let long = matchDic["long"] as? CLLocationDegrees , let radius = matchDic["radius"] as?  CLLocationDistance {
                let geofenceRegion = CLCircularRegion(center: CLLocationCoordinate2DMake(lat, long), radius:  min(radius, locationManager.maximumRegionMonitoringDistance), identifier: identifier)
                locationManager.stopMonitoring(for: geofenceRegion)
                dicIDs[identifier] = nil
                UserDefaults.standard.set(dicIDs, forKey: UDGeoFencIDs)
                debugPrint(UserDefaults.standard.dictionary(forKey: UDGeoFencIDs) as? [String : [String:Any]] ?? [:])
            }
        }
    }
  

}
 //MARK: - CLLocationManagerDelegate
extension GeoFenceManager : CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        mapView.showsUserLocation = status == .authorizedAlways
    }
    
    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        debugPrint("Monitoring failed for region with identifier: \(region?.identifier ?? "")")
        if let region = region, let dicIDs = UserDefaults.standard.dictionary(forKey: UDGeoFencIDs) as? [String : [String:AnyObject]] , let data = try? JSONDecoder().decode(GeoFenceManagerData.self, from: try JSONSerialization.data(withJSONObject: dicIDs[region.identifier] ?? [:], options: []))  {
            monitoringDidFailForRegionHandler?(region.identifier,data,region,error)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debugPrint("Location Manager failed with the following error: \(error)")
    }

    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let dicIDs = UserDefaults.standard.dictionary(forKey: UDGeoFencIDs) as? [String : [String:AnyObject]] , let data = try? JSONDecoder().decode(GeoFenceManagerData.self, from: try JSONSerialization.data(withJSONObject: dicIDs[region.identifier] ?? [:], options: []))  {
            didEnterRegionHandler?(region.identifier,data ,region)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let dicIDs = UserDefaults.standard.dictionary(forKey: UDGeoFencIDs) as? [String : [String:AnyObject]] , let data = try? JSONDecoder().decode(GeoFenceManagerData.self, from: try JSONSerialization.data(withJSONObject: dicIDs[region.identifier] ?? [:], options: []))  {
            didExitRegionHandler?(region.identifier,data,region)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if let dicIDs = UserDefaults.standard.dictionary(forKey: UDGeoFencIDs) as? [String : [String:AnyObject]] , let data = try? JSONDecoder().decode(GeoFenceManagerData.self, from: try JSONSerialization.data(withJSONObject: dicIDs[region.identifier] ?? [:], options: []))  {
            determineCurrentStateHandler?(region.identifier,data,region,state)
        }
    }

}
// MARK:- Alert Controller with OK Button
func showAlertView(_ strAlertTitle : String, strAlertMessage : String) -> UIAlertController {
    let alert = UIAlertController(title: strAlertTitle, message: strAlertMessage, preferredStyle: UIAlertController.Style.alert)
    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler:{ (ACTION :UIAlertAction!)in
    }))
    return alert
}

// MARK:- JSONType
fileprivate protocol JSONType: Decodable {
    var jsonValue: Any { get }
}

extension Int: JSONType {
    public var jsonValue: Any { return self }
}
extension String: JSONType {
    public var jsonValue: Any { return self }
}
extension Double: JSONType {
    public var jsonValue: Any { return self }
}
extension Bool: JSONType {
    public var jsonValue: Any { return self }
}

public struct AnyJSONType: JSONType {
    public let jsonValue: Any

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            jsonValue = intValue
        } else if let stringValue = try? container.decode(String.self) {
            jsonValue = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            jsonValue = boolValue
        } else if let doubleValue = try? container.decode(Double.self) {
            jsonValue = doubleValue
        } else if let doubleValue = try? container.decode(Array<AnyJSONType>.self) {
            jsonValue = doubleValue
        } else if let doubleValue = try? container.decode(Dictionary<String, AnyJSONType>.self) {
            jsonValue = doubleValue
        } else {
            throw DecodingError.typeMismatch(JSONType.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON tyep"))
        }
    }
}

