//
//  GeoFencingManager.swift
//  GeoFenceManager
//
//  Created by datt on 29/11/18.
//  Copyright © 2018 datt. All rights reserved.
//

import UIKit
import CoreLocation

class GeoFenceManager : NSObject{
    static let shared = GeoFenceManager()
    
    static let NotificationCenterGeoFenceDidEnterRegion = "NotificationCenterGeoFenceDidEnterRegion"
    static let NotificationCenterGeoFenceDidExitRegion = "NotificationCenterGeoFenceDidExitRegion"

    let locationManager = CLLocationManager()
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
            dicIDs[identifier] = ["identifier" : identifier , "Data": data , "lat" : location.latitude , "long": location.longitude , "radius" : Int(radius)]
            UserDefaults.standard.set(dicIDs, forKey: UDGeoFencIDs)
        } else {
            UserDefaults.standard.set([identifier : ["identifier" : identifier , "Data": data , "lat" : location.latitude , "long": location.longitude , "radius" : Int(radius)]], forKey: UDGeoFencIDs)
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
    func stopMonitoringGeoFence(withId MatchId : String) {
        if let dicIDs = UserDefaults.standard.dictionary(forKey: UDGeoFencIDs) as? [String : [String:Any]] , let matchDic = dicIDs[MatchId] {
            if let lat = matchDic["lat"] as? CLLocationDegrees , let long = matchDic["long"] as? CLLocationDegrees , let radius = matchDic["radius"] as?  CLLocationDistance {
                let geofenceRegion = CLCircularRegion(center: CLLocationCoordinate2DMake(lat, long), radius:  min(radius, locationManager.maximumRegionMonitoringDistance), identifier: MatchId)
                locationManager.stopMonitoring(for: geofenceRegion)
            }
        }
    }
  

}
extension GeoFenceManager : CLLocationManagerDelegate {
    //MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        mapView.showsUserLocation = status == .authorizedAlways
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed for region with identifier: \(region!.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with the following error: \(error)")
    }
//    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        if (status == CLAuthorizationStatus.authorizedAlways || status == CLAuthorizationStatus.authorizedWhenInUse) {
//            //App Authorized, stablish geofence
////            self.setupGeoFences()
//        }
//    }
//
//    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
//        print("Started Monitoring Region: \(region.identifier)")
//        locationManager.requestState(for: region)
//    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let title = "You Entered the Region" + region.identifier
        let info = ["data" : UserDefaults.standard.object(forKey: region.identifier) ?? "" , "identifier":region.identifier]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: GeoFenceManager.NotificationCenterGeoFenceDidEnterRegion), object: nil, userInfo: info)
        print(title)
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        let title = "You Left the Region" + region.identifier
        let info = ["data" : UserDefaults.standard.object(forKey: region.identifier) ?? "", "identifier":region.identifier]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: GeoFenceManager.NotificationCenterGeoFenceDidExitRegion), object: nil, userInfo: info)
        print(title)
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        
        switch state {
        case .inside: break
        case .outside: break
        default: break
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
    let alert = UIAlertController(title: strAlertTitle, message: strAlertMessage, preferredStyle: UIAlertControllerStyle.alert)
    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:{ (ACTION :UIAlertAction!)in
    }))
    return alert
}
