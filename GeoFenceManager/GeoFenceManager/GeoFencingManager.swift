//
//  GeoFencingManager.swift
//  GeoFenceManager
//
//  Created by datt on 29/11/18.
//  Copyright © 2018 datt. All rights reserved.
//

import UIKit
import CoreLocation

public struct GeoFenceManagerData : Decodable {
    let identifier : String
    let data : [String:AnyJSONType]?
    let lat : CLLocationDegrees
    let long : CLLocationDegrees
    let radius : Int
}

public class GeoFenceManager : NSObject {
    static let shared = GeoFenceManager()
    
    var didEnterRegionHandler: ((_ identifier:String,_ data:GeoFenceManagerData,_ region:CLRegion)->())?
    var didExitRegionHandler: ((_ identifier:String,_ data:GeoFenceManagerData,_ region:CLRegion)->())?
    var determineCurrentStateHandler: ((_ identifier:String,_ data:GeoFenceManagerData,_ region:CLRegion,_ state: CLRegionState)->())?

    fileprivate let locationManager = CLLocationManager()
    let UDGeoFencIDs = "GeoFencIDs"
    
    private override init() {
        super.init()
        startLocation()
    }
    
    func startLocation()  {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.startUpdatingLocation()
    }
    func stopLoaction() {
        locationManager.stopUpdatingLocation()
    }
    
    func startMonitoringGeoFence(radius: CLLocationDistance , location : CLLocationCoordinate2D , identifier : String , data : [String:AnyObject]) -> Bool {
        // 1
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
//            showAlert(withTitle:"Error", message: "Geofencing is not supported on this device!")
            print("Geofencing is not supported on this device!")
            return false
        }
        // 2
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
//            showAlert(withTitle:"Warning", message: "Your geotification is saved but will only be activated once you grant Geotify permission to access the device location.")
            print("Your geotification is saved but will only be activated once you grant Geotify permission to access the device location.")
            UIApplication.topViewController()?.present(showAlertView("Location Permission Denied", strAlertMessage: "To re-enable, please go to Settings and turn on Always Location Service for Geofencing."), animated: true){}
        }
        
        let geofenceRegion = CLCircularRegion(center: location, radius:  min(radius, locationManager.maximumRegionMonitoringDistance), identifier: identifier)
        
        if var dicIDs = UserDefaults.standard.dictionary(forKey: UDGeoFencIDs) as? [String : [String:Any]] {
            if dicIDs.count == 20 {
                print("Geofencing max Limit for Monitoring")
                return false
            }
            if let _ = dicIDs[identifier] {
                print("already added to Geofencing")
                return true
            }
            dicIDs[identifier] = ["identifier" : identifier , "data": data , "lat" : location.latitude , "long": location.longitude , "radius" : Int(radius)]
            UserDefaults.standard.set(dicIDs, forKey: UDGeoFencIDs)
        } else {
            UserDefaults.standard.set([identifier : ["identifier" : identifier , "data": data , "lat" : location.latitude , "long": location.longitude , "radius" : Int(radius)]], forKey: UDGeoFencIDs)
        }
        
        
        geofenceRegion.notifyOnExit = true
        geofenceRegion.notifyOnEntry = true
        locationManager.startMonitoring(for: geofenceRegion)
        return true
    }
    func stopAllMonitoringGeoFence() {
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
    func stopMonitoringGeoFence(withID identifier : String) {
        if var dicIDs = UserDefaults.standard.dictionary(forKey: UDGeoFencIDs) as? [String : [String:Any]] , let matchDic = dicIDs[identifier] {
            if let lat = matchDic["lat"] as? CLLocationDegrees , let long = matchDic["long"] as? CLLocationDegrees , let radius = matchDic["radius"] as?  CLLocationDistance {
                let geofenceRegion = CLCircularRegion(center: CLLocationCoordinate2DMake(lat, long), radius:  min(radius, locationManager.maximumRegionMonitoringDistance), identifier: identifier)
                locationManager.stopMonitoring(for: geofenceRegion)
                dicIDs[identifier] = nil
                UserDefaults.standard.set(dicIDs, forKey: UDGeoFencIDs)
                print(UserDefaults.standard.dictionary(forKey: UDGeoFencIDs) as? [String : [String:Any]] ?? [:])
            }
        }
    }
  

}
extension GeoFenceManager : CLLocationManagerDelegate {
    //MARK: - CLLocationManagerDelegate
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        mapView.showsUserLocation = status == .authorizedAlways
    }
    
    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed for region with identifier: \(region!.identifier)")
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with the following error: \(error)")
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
extension UIApplication {
    ///  Get the top most view controller from the base view controller; default param is UIWindow's rootViewController
    public class func topViewController(_ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        return base
    }
}
// MARK:- Alert Controller with OK Button
func showAlertView(_ strAlertTitle : String, strAlertMessage : String) -> UIAlertController {
    let alert = UIAlertController(title: strAlertTitle, message: strAlertMessage, preferredStyle: UIAlertController.Style.alert)
    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler:{ (ACTION :UIAlertAction!)in
    }))
    return alert
}

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

