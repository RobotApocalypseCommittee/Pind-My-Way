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
import Polyline

let spaceOnTop: CGFloat = 50.0
// Really hacky for now to ignore the safe area
let spaceOnBottom: CGFloat = -(UIApplication.shared.delegate as! AppDelegate).window!.safeAreaInsets.bottom

class ViewController: UIViewController {
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation? = nil
    var mapView: GMSMapView!
    
    var addressResultsViewController: GMSAutocompleteResultsViewController?
    var addressSearchController: UISearchController?
    
    var zoomLevel: Float = 15.0
    
    var marker : GMSMarker = GMSMarker()
    
    var routePolylines: Array<Array<GMSPolyline>> = []
    var routeCoordinates: Array<Array<CLLocationCoordinate2D>> = []

    @IBOutlet weak var addressBar: UISearchBar!

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
        
        // Magic 5.0 is magic
        let camera = GMSCameraPosition.camera(withLatitude: 0.0, longitude: 0.0, zoom: zoomLevel)
        self.mapView = GMSMapView.map(withFrame: CGRect(x: self.view.bounds.minX, y: window.safeAreaInsets.top+spaceOnTop+5.0, width: self.view.bounds.width, height: self.view.bounds.height-(spaceOnTop+spaceOnBottom+(window.safeAreaInsets.bottom+window.safeAreaInsets.top))), camera: camera)
        
        self.view.addSubview(mapView)
        
        mapView.settings.myLocationButton = true
        mapView.isMyLocationEnabled = true
        mapView.delegate = self
        
        addressResultsViewController = GMSAutocompleteResultsViewController()
        addressResultsViewController?.delegate = self
        
        addressSearchController = UISearchController(searchResultsController: addressResultsViewController)
        addressSearchController?.searchResultsUpdater = addressResultsViewController
        
        let searchView = UIView(frame: CGRect(x: 0, y: window.safeAreaInsets.top, width: self.view.bounds.width, height: spaceOnTop))
        
        searchView.addSubview((addressSearchController?.searchBar)!)
        self.view.addSubview(searchView)
        addressSearchController?.searchBar.sizeToFit()
        addressSearchController?.searchBar.isTranslucent = false
        addressSearchController?.searchBar.placeholder = "Enter a location"
        
        definesPresentationContext = true
        
        Utils.getPollution(location: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0))
    }
    

    // Gets directions and draws them on the map
    func getDirections(endCoordinates: CLLocationCoordinate2D) {
        let startCoordinates: CLLocationCoordinate2D = currentLocation!.coordinate
        
        routePolylines = []
        routeCoordinates = []

        DispatchQueue.global(qos: .userInitiated).async {
            Utils.getDirections(from: startCoordinates, to: endCoordinates) { json in
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
                    let update = GMSCameraUpdate.fit(GMSCoordinateBounds(coordinate: southWestCoordinates, coordinate: northEastCoordinates), with: UIEdgeInsets(top: 75.0, left: 15.0, bottom: 15.0, right: 15.0))
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
        var points: Array<CLLocationCoordinate2D> = []
        var pointsLastIndex = -1
        
        var nonDrawnPointsIncluded: Array<CLLocationCoordinate2D> = []

        for leg in route["legs"].array! {
            for step in leg["steps"].array! {
                let stepPolyline = Polyline(encodedPolyline: step["polyline"]["points"].string!)
                
                for pointCoordinate in stepPolyline.coordinates! {
                    points.append(pointCoordinate)
                    nonDrawnPointsIncluded.append(pointCoordinate)
                    pointsLastIndex += 1
                    
                    if pointsLastIndex != 0 && Utils.getDistance(between: pointCoordinate, and: points[pointsLastIndex-1]) > 10 {
                        let pointBefore = points[pointsLastIndex-1]
                        let fullDistanceBetween = Utils.getDistance(between: pointCoordinate, and: points[pointsLastIndex-1])
                        
                        for distance in stride(from: 10, to: fullDistanceBetween, by: 10) {
                            let newPoint = CLLocationCoordinate2D(latitude: pointBefore.latitude+((pointCoordinate.latitude-pointBefore.latitude)*(distance/fullDistanceBetween)), longitude: pointBefore.longitude+((pointCoordinate.longitude-pointBefore.longitude)*(distance/fullDistanceBetween)))
                            nonDrawnPointsIncluded.append(newPoint)
                        }
                    }
                }

            }
        }

        routeCoordinates.append(nonDrawnPointsIncluded)
        
        let overallPolyline: String = encodeCoordinates(points)
        let path = GMSPath(fromEncodedPath: overallPolyline)
        
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
        
        routePolylines.append([polyline, underPolyline])
    }
    
}


extension ViewController: GMSMapViewDelegate {
    // Called when user touches to place a marker
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        if routePolylines.count == 0 {
            print("Marker placed at \(coordinate.latitude), \(coordinate.longitude)")
            placeMarker(mapView, at: coordinate)
            getDirections(endCoordinates: coordinate)
        } else {
            var smallestDistances: Array<Double> = []
            for coordinatesForRoute in routeCoordinates {
                smallestDistances.append(coordinatesForRoute.map { Utils.getDistance(between: coordinate, and: $0) }.min()!)
            }

            // 15.60405 is the zoom level at which 50m is appropriate
            // When you get into very zoomed in levels, google maps gets the point at which you clicked slightly wrong lat-long-wise, so if it's under 30m, we assume you tried to click it anyway
            if smallestDistances.min() != nil && (smallestDistances.min()! < 30 || smallestDistances.min()! < Double(50 * pow(2, 15.60405-mapView.camera.zoom))) {
                let indexOfSelected = smallestDistances.firstIndex(of: smallestDistances.min()!)!
                
                for i in 0...routePolylines.count-1 {
                    let selected = i == indexOfSelected
                    
                    let polyline = routePolylines[i][0]
                    polyline.strokeWidth = selected ? 3.0 : 2.5
                    polyline.strokeColor = selected ? UIColor(red: 26.0/255, green: 142.0/255, blue: 255.0/255, alpha: 1.0) : UIColor.lightGray
                    polyline.zIndex = selected ? 100 : 2
                    
                    let underPolyline = routePolylines[i][1]
                    underPolyline.strokeWidth = selected ? 6.0 : 5.0
                    underPolyline.strokeColor = selected ? UIColor(red: 26.0/255, green: 100.0/255, blue: 255.0/255, alpha: 1.0) : UIColor.gray
                    underPolyline.zIndex = selected ? 99 : 1
                }
            } else {
                print("Marker placed at \(coordinate.latitude), \(coordinate.longitude)")
                placeMarker(mapView, at: coordinate)
                getDirections(endCoordinates: coordinate)
            }
        }
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
        
        // Basically sets reasonable bounds to bias for in the place search
        let autocompleteBiasBounds = GMSCoordinateBounds(coordinate: CLLocationCoordinate2D(latitude: location.coordinate.latitude+0.1, longitude: location.coordinate.longitude+0.1), coordinate: CLLocationCoordinate2D(latitude: location.coordinate.latitude-0.1, longitude: location.coordinate.longitude-0.1))
        
        addressResultsViewController?.autocompleteBounds = autocompleteBiasBounds
        
        
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

extension ViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didAutocompleteWith place: GMSPlace) {
        print(place)
        
        addressSearchController?.isActive = false
        
        placeMarker(mapView, at: place.coordinate)
        
        getDirections(endCoordinates: place.coordinate)
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didFailAutocompleteWithError error: Error) {
        print("Error: ", error.localizedDescription)
    }
    
    func didRequestAutocompletePredictions(forResultsController resultsController: GMSAutocompleteResultsViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(forResultsController resultsController: GMSAutocompleteResultsViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}
