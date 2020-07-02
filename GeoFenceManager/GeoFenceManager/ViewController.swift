//
//  ViewController.swift
//  GeoFenceManager
//
//  Created by datt on 29/11/18.
//  Copyright © 2018 datt. All rights reserved.
//

import UIKit
import MapKit

struct Annotation {
    let title : String
    let coordinate : CLLocationCoordinate2D
}

class ViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    // set initial location in Honolulu
    let initialLocation = CLLocation(latitude: 21.28983511754285, longitude: -157.70258891066896)
    let annotations = [
        Annotation(title: "a", coordinate: CLLocationCoordinate2D(latitude: 21.300950976178427, longitude: -157.7094553657471)),
        Annotation(title: "b", coordinate: CLLocationCoordinate2D(latitude: 21.296472745754965, longitude: -157.70400511702883)),
        Annotation(title: "c", coordinate: CLLocationCoordinate2D(latitude: 21.28983511754285, longitude: -157.70258891066896)),
        Annotation(title: "d", coordinate: CLLocationCoordinate2D(latitude: 21.294633433015687, longitude: -157.70915495833742)),
        Annotation(title: "e", coordinate: CLLocationCoordinate2D(latitude: 21.289515224276535, longitude: -157.7240465827881)),
        Annotation(title: "f", coordinate: CLLocationCoordinate2D(latitude: 21.275039325842233, longitude: -157.7070091911255)),
        Annotation(title: "g", coordinate: CLLocationCoordinate2D(latitude: 21.29151454577244, longitude: -157.69057261428225)),
        Annotation(title: "h", coordinate: CLLocationCoordinate2D(latitude: 21.303749800894, longitude: -157.69267546614992))
    ]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addGeoFenceHandler()
        GeoFenceManager.shared.startLocation()
        centerMapOnLocation(location: initialLocation)
        GeoFenceManager.shared.stopAllMonitoringGeoFence()
        for obj in annotations {
            let annotation = MKPointAnnotation()
            annotation.title = obj.title
            annotation.coordinate = obj.coordinate
            mapView.addAnnotation(annotation)
            _ = GeoFenceManager.shared.startMonitoringGeoFence(radius: 100, location: obj.coordinate, identifier: obj.title, data: ["key":"value" as AnyObject])
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            GeoFenceManager.shared.stopMonitoringGeoFence(withID: "a")
        }
    }
    
    let regionRadius: CLLocationDistance = 5000
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    fileprivate func addGeoFenceHandler() {
        GeoFenceManager.shared.determineCurrentStateHandler = { (identifier,data,region,state) in
            switch state {
            case .unknown: break
            case .inside:
                print("You are inside Region : \(identifier)")
            case .outside:
                print("You are outside Region : \(identifier)")
            }
        }
        GeoFenceManager.shared.didEnterRegionHandler = { [weak self] (identifier,data,region) in
            print("You Entered the Region: " + identifier)
            self?.showToast(message: "You Entered the Region: \(identifier)")
            print("Data: \(data)")
        }
        GeoFenceManager.shared.didExitRegionHandler = { [weak self] (identifier,data,region) in
            print("You Left the Region: " + identifier)
            self?.showToast(message: "You Left the Region: \(identifier)")
            print("Data: \(data)")
//            print("Data: \(String(describing: data.data?["key"]?.jsonValue as? String))")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

extension UIViewController {
    
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 125, y: self.view.frame.size.height-100, width: 250, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 5.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
}
