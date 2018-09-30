//
//  ViewController.swift
//  Pind-My-Way-Map
//
//  Created by Atto Allas on 30/09/2018.
//  Copyright © 2018 Atto Allas. All rights reserved.
//

import UIKit
import GoogleMaps
import SwiftyJSON

let spaceOnTop: CGFloat = 100.0
let spaceOnBottom: CGFloat = 100.0

class ViewController: UIViewController {
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation? = nil
    var mapView: GMSMapView!
    
    var zoomLevel: Float = 15.0
    
    var marker : GMSMarker = GMSMarker()
    
    @IBOutlet weak var addressField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        addressField.delegate = self
        
        
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        
        let camera = GMSCameraPosition.camera(withLatitude: 0.0, longitude: 0.0, zoom: zoomLevel)
        self.mapView = GMSMapView.map(withFrame: CGRect(x: self.view.bounds.minX, y: self.view.bounds.minY+spaceOnTop, width: self.view.bounds.width, height: self.view.bounds.height-(spaceOnTop+spaceOnBottom)), camera: camera)
        
        self.view.addSubview(mapView)
        
        mapView.settings.myLocationButton = true
        mapView.isMyLocationEnabled = true
        mapView.delegate = self
    }
    

    // Gets directions and draws them on the map
    func getDirections(endCoordinates: CLLocationCoordinate2D) {
        let startCoordinates: CLLocationCoordinate2D = currentLocation!.coordinate
        //let endCoordinates: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 51.498142, longitude: -0.128676)
        DispatchQueue.global(qos: .userInitiated).async {
            DirectionManager.getDirections(from: startCoordinates, to: endCoordinates) { json in
                let routes = json!["routes"].array!
                self.drawRoute(route: routes[0])
            }
        }
    }
    
    // Takes a route, gets the overview polyline, decodes it and draws it
    func drawRoute(route: JSON) {
        let points = String(describing: route["overview_polyline"]["points"])
        let path = GMSPath(fromEncodedPath: points)
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 3.0
        polyline.strokeColor = UIColor.red
        polyline.map = mapView
    }
    
    @IBAction func markerLocationConfirmed(_ sender: UIButton) {
        getDirections(endCoordinates: marker.position)
    }
    

}


extension ViewController: GMSMapViewDelegate {
    // Called when user touches to place a marker
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D){
        print("Marker placed at \(coordinate.latitude), \(coordinate.longitude)")
        mapView.clear()
        marker = GMSMarker(position: coordinate)
        marker.appearAnimation = GMSMarkerAnimation.pop
        marker.map = mapView
    }
}


extension ViewController: CLLocationManagerDelegate {
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
        
        if currentLocation == nil {
            mapView.animate(to: camera)
            currentLocation = location
        }
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("yeeting")
        textField.resignFirstResponder()
        
        if currentLocation != nil {
            self.getDirections(endCoordinates: CLLocationCoordinate2D(latitude: 51.498142, longitude: -0.128676))
        }
        
        return true
    }
}
