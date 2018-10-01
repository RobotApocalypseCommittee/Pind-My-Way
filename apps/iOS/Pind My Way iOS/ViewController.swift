//
//  ViewController.swift
//  Pind-My-Way-Map
//
//  Created by Atto Allas on 30/09/2018.
//  Copyright © 2018 Atto Allas. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import SwiftyJSON

let spaceOnTop: CGFloat = 50.0
// Really hacky for now to ignore the safe area
let spaceOnBottom: CGFloat = -(UIApplication.shared.delegate as! AppDelegate).window!.safeAreaInsets.bottom

class ViewController: UIViewController {
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation? = nil
    var mapView: GMSMapView!
    
    var zoomLevel: Float = 15.0
    
    var marker : GMSMarker = GMSMarker()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        let window = (UIApplication.shared.delegate as! AppDelegate).window!
        
        let camera = GMSCameraPosition.camera(withLatitude: 0.0, longitude: 0.0, zoom: zoomLevel)
        self.mapView = GMSMapView.map(withFrame: CGRect(x: self.view.bounds.minX, y: window.safeAreaInsets.top+spaceOnTop, width: self.view.bounds.width, height: self.view.bounds.height-(spaceOnTop+spaceOnBottom+(window.safeAreaInsets.bottom+window.safeAreaInsets.top))), camera: camera)
        
        self.view.addSubview(mapView)
        
        mapView.settings.myLocationButton = true
        mapView.isMyLocationEnabled = true
        mapView.delegate = self
    }
    

    // Gets directions and draws them on the map
    func getDirections(endCoordinates: CLLocationCoordinate2D) {
        let startCoordinates: CLLocationCoordinate2D = currentLocation!.coordinate

        DispatchQueue.global(qos: .userInitiated).async {
            DirectionManager.getDirections(from: startCoordinates, to: endCoordinates) { json in
                let routes = json!["routes"].array!
                if routes.count == 0 {
                    self.mapView.clear()
                
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "No routes found", message: "There were no cycling routes found to that location, please try another", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
            
                    return
                }
                
                // The coordinates are initialised so that none of the earth is in this right now, it's actually the opposite of the full earth
                var southWestCoordinates = CLLocationCoordinate2D(latitude: 90.0, longitude: 180.0)
                var northEastCoordinates = CLLocationCoordinate2D(latitude: -90.0, longitude: -180.0)
                
                for i in 0...routes.count-1 {
                    // What this horror show does it it updates the coordinates with the most out-there coordinates to make the bounds to show after the location has been selected so all of the routes are fully visible
                    southWestCoordinates.latitude = min(routes[i]["bounds"]["southwest"]["lat"].double!, southWestCoordinates.latitude)
                    southWestCoordinates.longitude = min(routes[i]["bounds"]["southwest"]["lng"].double!, southWestCoordinates.longitude)
                    northEastCoordinates.latitude = max(routes[i]["bounds"]["northeast"]["lat"].double!, northEastCoordinates.latitude)
                    northEastCoordinates.longitude = max(routes[i]["bounds"]["northeast"]["lng"].double!, northEastCoordinates.longitude)
                }
                
                DispatchQueue.main.async {
                    let update = GMSCameraUpdate.fit(GMSCoordinateBounds(coordinate: southWestCoordinates, coordinate: northEastCoordinates), withPadding: 75.0)
                    self.mapView.animate(with: update)
                    
                    // I do these as two seperate things so the resize happens first of all
                    for i in 0...routes.count-1 {
                        self.drawRoute(route: routes[i], asSelected: i == 0)
                    }
                }
            }
        }
    }
    
    // Takes a route, gets the overview polyline, decodes it and draws it
    func drawRoute(route: JSON, asSelected selected: Bool) {
        let points = String(describing: route["overview_polyline"]["points"])
        let path = GMSPath(fromEncodedPath: points)
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = selected ? 3.0 : 2.5
        polyline.strokeColor = selected ? UIColor(red: 26.0/255, green: 142.0/255, blue: 255.0/255, alpha: 1.0) : UIColor.lightGray
        polyline.zIndex = selected ? 100 : 2
        polyline.map = mapView

        let underPolyline = GMSPolyline(path: path)
        underPolyline.strokeWidth = selected ? 6.0 : 5.0
        underPolyline.strokeColor = selected ? UIColor(red: 26.0/255, green: 100.0/255, blue: 255.0/255, alpha: 1.0) : UIColor.gray
        underPolyline.zIndex = selected ? 99 : 1
        underPolyline.map = mapView
    }
    
    @IBAction func searchButtonPressed(_ sender: Any) {
        let autocompleteViewController = GMSAutocompleteViewController()
        autocompleteViewController.delegate = self
        
        if currentLocation != nil {
            // Basically sets reasonable bounds to bias for in the place search
            let autocompleteBiasBounds = GMSCoordinateBounds(coordinate: CLLocationCoordinate2D(latitude: currentLocation!.coordinate.latitude+0.1, longitude: currentLocation!.coordinate.longitude+0.1), coordinate: CLLocationCoordinate2D(latitude: currentLocation!.coordinate.latitude-0.1, longitude: currentLocation!.coordinate.longitude-0.1))
            autocompleteViewController.autocompleteBounds = autocompleteBiasBounds
        }
        
        self.present(autocompleteViewController, animated: true, completion: nil)
    }
    
}


extension ViewController: GMSMapViewDelegate {
    // Called when user touches to place a marker
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D){
        print("Marker placed at \(coordinate.latitude), \(coordinate.longitude)")
        placeMarker(mapView, at: coordinate)
        getDirections(endCoordinates: coordinate)
    }
    
    func placeMarker(_ mapView: GMSMapView, at coordinate: CLLocationCoordinate2D) {
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

extension ViewController: GMSAutocompleteViewControllerDelegate {
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        print(place)
        dismiss(animated: true, completion: nil)
        
        placeMarker(mapView, at: place.coordinate)
        
        getDirections(endCoordinates: place.coordinate)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print("Error: \(error)")
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        print("Autocomplete cancelled")
        dismiss(animated: true, completion: nil)
    }
    
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}
