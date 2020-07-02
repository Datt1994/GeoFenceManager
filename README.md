# GeoFenceManager
[![Language: Swift 5](https://img.shields.io/badge/language-swift5-f48041.svg?style=flat)](https://developer.apple.com/swift)
[![License](https://img.shields.io/cocoapods/l/DPOTPView.svg?style=flat)](https://github.com/Datt1994/GeoFenceManager/blob/master/LICENSE)

GeoFenceManager is Geofencing helper class


## Add Manually 

Download Project and copy-paste `GeoFenceManager.swift` file into your project 


## How to use

**Start Location Sevice and Authorization** 
```swift
GeoFenceManager.shared.startLocation()
```

**Start Monitoring GeoFence Region**
```swift
 /// Using this this method you can start monitoring some region that provided by you with Parameters.When current location enter or exit any monitoring region following handler call, so use this handlers
 /// didEnterRegionHandler
 /// didExitRegionHandler
 /// determineCurrentStateHandler
 /// 
 /// - Parameters:
 ///   - radius: radius gives the distance in meters between the center and the region's boundary
 ///   - location: location gives the coordinates of center of the region
 ///   - identifier: unique identifier
 ///   - data: cutom data given when you anter or exit region
 ///   - completion: completion give you state, 'success' when GeoFence region Monitoring started successfully, 'failure' when some error occur with failure string
 
GeoFenceManager.shared.startMonitoringGeoFence(radius: 100, location: CLLocationCoordinate2D(latitude: 21.28983511754285, longitude: -157.70258891066896), identifier: "id500", data: ["key":"value" as AnyObject]) { result in
    switch result {
    case .success:
        print("Region'id500' start monitoring successfully")
    case .failure(let reason):
        print("Region'id500' failed to start monitoring with reason: " + reason)
    }
}
```

**GeoFence Region Monitoring Handlers**
```swift
 /// Call When your current location enter some monitoring region
GeoFenceManager.shared.didEnterRegionHandler = { [weak self] (identifier,data,region) in
    print("You Entered the Region: " + identifier)
}

 /// Call When your current location exit some monitoring region
GeoFenceManager.shared.didExitRegionHandler = { [weak self] (identifier,data,region) in
    print("You Left the Region: " + identifier)
}

 /// Call When your current location determine state form some monitoring region
GeoFenceManager.shared.determineCurrentStateHandler = { [weak self] (identifier,data,region,state) in
    switch state {
    case .unknown: break
    case .inside:
        print("You are inside Region : \(identifier)")
    case .outside:
        print("You are outside Region : \(identifier)")
    }
}

 /// Call When fail to start monitoring form some region
GeoFenceManager.shared.monitoringDidFailForRegionHandler = { [weak self] (identifier,data,region,error) in
    print(error.localizedDescription)
}
```

**Stop GeoFence Monitoring Region**
```swift
 /// Stop all monitoring region used by GeoFenceManager class
GeoFenceManager.shared.stopAllMonitoringGeoFence()

 /// Stop monitoring region for identifier "id500"
GeoFenceManager.shared.stopMonitoringGeoFence(withID: "id500")
```
