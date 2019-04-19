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
    
    var addressResultsViewController = GMSAutocompleteResultsViewController()
    var addressSearchController = UISearchController()
    
    var zoomLevel: Float = 15.0
    
    var marker : GMSMarker = GMSMarker()
    var selectedRouteIndex = 0
    
    var routeJSONs: Array<JSON> = []
    var routePolylines: Array<Array<GMSPolyline>> = []
    var routeCoordinates: Array<Array<CLLocationCoordinate2D>> = []
    var routePollutions: [[String : [String : Any]]] = []
    
    var networkCheckerTimer = Timer()
    var keepGoButtonHidden = true
    
    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var goControlView: UIControl!
    var savedGoControlViewFrame: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    @IBOutlet weak var bikeIcon: UIImageView!
    @IBOutlet weak var noWifiLabel: UILabel!
    @IBOutlet weak var noWifiImage: UIImageView!
    
    override func viewDidLoad() {
        UIApplication.shared.windows.first?.layer.speed = 1
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let app = UserDefaults.standard
        
        // Gets the interval in seconds between now and the last pollution getting of the app (O if this is the first run)
        var interval : Int = 0;
        if let date2 = app.object(forKey: "date") as? Date {
            interval = Int(Date().timeIntervalSince(date2))
        }

        // Reloads pollution if it's been a week since last getting, or this is first run
        if interval > 60*60*24*7 || interval == 0 {
            print("Reloading pollution!")
            
            // Sets new last pollution getting time
            let date = Date()
            app.set(date, forKey: "date")
            
            //Fetches pollution data
            let url = URL(string: "http://api.erg.kcl.ac.uk/AirQuality/Daily/MonitoringIndex/Latest/GroupName=London/json")
            let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
                if let data = data {
                    do {
                        pollutionResp = try JSON(data: data)
                        print("Info: Pollution: Data Loaded")
                        
                        var tosave : [String] = [];
                        
                        for area in pollutionResp["DailyAirQualityIndex"]["LocalAuthority"] {
                            if area.1["Site"].exists() {
                                for site in area.1["Site"] {
                                    // Saves locally for this run
                                    localAuthorities.append(site.1)
                                    // Each JSON becomes a string representation as JSON objects cannot be stored in UserDefaults just like that
                                    tosave.append(site.1.rawString()!)
                                }
                            }
                        }
                        // Saves in UserDefaults
                        app.set(tosave, forKey: "localAuthorities")
                    }  catch let error {
                        print("Error: Polution: \(error.localizedDescription)")
                    }
                } else if let error = error {
                    print("Error: Polution: \(error.localizedDescription)")
                }
            }
            task.resume()
        }
        else {
            // Reloads pollution from UserDefaults, re-serializing JSONs from strings
            if let data = app.object(forKey: "localAuthorities") {
                localAuthorities = []
                for jsonstr in data as! [String]  {
                    let json = JSON.init(parseJSON: jsonstr)
                    localAuthorities.append(json)
                }
            }
        }
        
        // This is so that it's over the GMSMapView
        goControlView.layer.zPosition = 1
        bikeIcon.layer.zPosition = 2
        
        // So that it's under the map until it's needed
        animationView.layer.zPosition = -1
        animationView.layer.cornerRadius = 25-goControlViewBezel
        
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        let window = (UIApplication.shared.delegate as! AppDelegate).window!
        
        let camera = GMSCameraPosition.camera(withLatitude: 0.0, longitude: 0.0, zoom: zoomLevel)
        
        self.mapView = GMSMapView.map(withFrame: CGRect(x: self.view.bounds.minX, y: window.safeAreaInsets.top+spaceOnTop, width: self.view.bounds.width, height: self.view.bounds.height-(spaceOnTop+spaceOnBottom+(window.safeAreaInsets.bottom+window.safeAreaInsets.top))), camera: camera)
        
        self.view.insertSubview(mapView, at: 0)
        
        mapView.settings.myLocationButton = false
        mapView.isMyLocationEnabled = true
        mapView.delegate = self
        
        addressResultsViewController = GMSAutocompleteResultsViewController()
        addressResultsViewController.delegate = self
        
        addressSearchController = UISearchController(searchResultsController: addressResultsViewController)
        addressSearchController.searchResultsUpdater = addressResultsViewController
        
        let searchView = UIView(frame: CGRect(x: 0, y: window.safeAreaInsets.top, width: self.view.bounds.width, height: spaceOnTop))
        
        searchView.addSubview(addressSearchController.searchBar)
        
        self.view.addSubview(searchView)

        addressSearchController.searchBar.sizeToFit()
        addressSearchController.searchBar.placeholder = "Enter a location"
        
        definesPresentationContext = true
        
        // TODO make this better!
        networkCheckerTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if !Reachability.isConnectedToNetwork() {
                self.mapView.isHidden = true
                self.addressSearchController.searchBar.isHidden = true
                self.view.backgroundColor = .white
                
                self.keepGoButtonHidden = self.goControlView.isHidden
                
                self.goControlView.isHidden = true
                self.bikeIcon.isHidden = true
                
                self.noWifiLabel.isHidden = false
                self.noWifiImage.isHidden = false
                //print("Info: Connection: The device is not connected to the internet.")
            } else {
                self.mapView.isHidden = false
                self.addressSearchController.searchBar.isHidden = false
                // Same colour as search bar, ish
                self.view.backgroundColor = UIColor(displayP3Red: 199/255, green: 198/255, blue: 204/255, alpha: 1)
                
                if !self.keepGoButtonHidden {
                    self.goControlView.isHidden = false
                    self.bikeIcon.isHidden = false
                }
                
                self.noWifiLabel.isHidden = true
                self.noWifiImage.isHidden = true
                //print("Info: Connection: The device is connected to the internet.")
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Only shows the introduction if the user has never completed it
        if !UserDefaults.standard.bool(forKey: "introDone") {
            performSegue(withIdentifier: "toIntroduction", sender: self)
        }
    }
    
    // Proof of concept for resizing the search bar (for the menu icon soon to come)
    override func viewDidLayoutSubviews() {
        var addressSearchBarFrame = addressSearchController.searchBar.frame
        addressSearchBarFrame.size.height = spaceOnTop // Either this or the magic 5.0 is needed
        addressSearchController.searchBar.frame = addressSearchBarFrame
    }
    
    @IBAction func goControlView_touchUpInside(_ sender: Any) {
        #if DEBUG
        UserDefaults.standard.set(false, forKey: "introDone")
        #endif
        
        print(Utils.getRouteDataForBluetooth(route: routeJSONs[selectedRouteIndex], withStart: currentLocation!.coordinate).hexEncodedString())
        print(Utils.getRouteDataForBluetooth(route: routeJSONs[selectedRouteIndex]).hexEncodedString())
        
        self.performSegue(withIdentifier: "toGo", sender: self)
    }
    
    @IBAction func returnFromSegueActions(sender: UIStoryboardSegue) {
        // Just here
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toGo" {
            let destinationVC = segue.destination as! GoViewController
            destinationVC.routeJSON = routeJSONs[selectedRouteIndex]
            destinationVC.currentLocation = currentLocation?.coordinate
            destinationVC.pollutionDict = routePollutions[selectedRouteIndex]
        }
    }
    
    // Gets directions and draws them on the map
    func getDirections(endCoordinates: CLLocationCoordinate2D) {
        let startCoordinates: CLLocationCoordinate2D = currentLocation!.coordinate

        routePolylines = []
        routeCoordinates = []
        routePollutions = []

        DispatchQueue.global(qos: .userInitiated).async {
            Utils.getDirections(from: startCoordinates, to: endCoordinates) { json in
                let routes = json!["routes"].array!
                //print(routes[0])
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
                
                // These two sets make sure the current location (start point) and end point are in the bounds
                if let location = self.currentLocation {
                    southWestCoordinates.latitude = min(location.coordinate.latitude, southWestCoordinates.latitude)
                    southWestCoordinates.longitude = min(location.coordinate.longitude, southWestCoordinates.longitude)
                    northEastCoordinates.latitude = max(location.coordinate.latitude, northEastCoordinates.latitude)
                    northEastCoordinates.longitude = max(location.coordinate.longitude, northEastCoordinates.longitude)
                }
                
                southWestCoordinates.latitude = min(endCoordinates.latitude, southWestCoordinates.latitude)
                southWestCoordinates.longitude = min(endCoordinates.longitude, southWestCoordinates.longitude)
                northEastCoordinates.latitude = max(endCoordinates.latitude, northEastCoordinates.latitude)
                northEastCoordinates.longitude = max(endCoordinates.longitude, northEastCoordinates.longitude)
                
                DispatchQueue.main.async {
                    let update: GMSCameraUpdate
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        update = GMSCameraUpdate.fit(GMSCoordinateBounds(coordinate: southWestCoordinates, coordinate: northEastCoordinates), with: UIEdgeInsets(top: 65.0, left: 15.0, bottom: 15.0, right: 15.0))
                    } else {
                        update = GMSCameraUpdate.fit(GMSCoordinateBounds(coordinate: southWestCoordinates, coordinate: northEastCoordinates), with: UIEdgeInsets(top: 45.0, left: 25.0, bottom: 25.0, right: 25.0))
                    }
                    
                    self.mapView.animate(with: update)
                    
                    // I do these as two seperate things so the resize happens first of all
                    for i in 0...routes.count-1 {
                        self.drawRoute(route: routes[i], asSelected: i == 0, name: "Route \(i+1)")
                        self.routeJSONs.append(routes[i])
                    }
                    
                    // And finally show the go button if it was hidden
                    if self.goControlView.isHidden {
                        let controlFrame = self.goControlView.frame
                        let bikeFrame = self.bikeIcon.frame
                        
                        let center = self.goControlView.center
                        let invisibleRect = CGRect(origin: center, size: CGSize(width: 1, height: 1))
                        
                        self.goControlView.frame = invisibleRect
                        self.bikeIcon.frame = invisibleRect
                        
                        self.goControlView.isHidden = false
                        self.bikeIcon.isHidden = false

                        UIView.animate(withDuration: 0.5, animations: { () -> Void in
                            
                            self.goControlView.frame = controlFrame
                            
                            self.bikeIcon.frame = bikeFrame
                            
                        })
                        
                        self.goControlView.addCornerRadiusAnimation(from: 0, to: 25, duration: 0.5, withTimingFunction: .easeInEaseOut)
                    }
                }
            }
        }
    }
    
    // Takes a route, gets the overview polyline, decodes it and draws it
    func drawRoute(route: JSON, asSelected selected: Bool, name: String) {
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
        
        // get the 'middle point where the marker is placed' this needs to be better for routes that are really similar
        let pointCount = path!.count()
        let midpoint = path!.coordinate(at: pointCount/2)
        marker = GMSMarker(position: midpoint)
        marker.appearAnimation = GMSMarkerAnimation.pop
        
        // store info about what the marker's info window should display in the marker
        marker.title = name
        marker.icon = #imageLiteral(resourceName: "RouteInfo")
        let pollutionInfo = Utils.getRoutePollution(route: nonDrawnPointsIncluded)
        routePollutions.append(pollutionInfo)
        
        var description = "N/A"
        
        print(pollutionInfo)
        
        if pollutionInfo["NO2"] != nil {
            description = ""
            description.append(contentsOf: "NO₂ rating: \(pollutionInfo["NO2"]!["total"]!)\n")
            description.append(contentsOf: "SO₂ rating: \(pollutionInfo["SO2"]!["total"]!)\n")
            description.append(contentsOf: "PM10 rating: \(pollutionInfo["PM10"]!["total"]!)\n")
            description.append(contentsOf: "PM25 rating: \(pollutionInfo["PM25"]!["total"]!)\n")
            description.append(contentsOf: "O₃ rating: \(pollutionInfo["O3"]!["total"]!)")
        }
        print(description)
        marker.snippet = description
        marker.map = mapView
        
        let underPolyline = GMSPolyline(path: path)
        underPolyline.strokeWidth = selected ? 6.0 : 5.0
        underPolyline.strokeColor = selected ? UIColor(red: 26.0/255, green: 100.0/255, blue: 255.0/255, alpha: 1.0) : UIColor.gray
        underPolyline.zIndex = selected ? 99 : 1
        underPolyline.map = mapView
        
        let overviewPoints = String(describing: route["overview_polyline"]["points"])
        let overviewPath = GMSPath(fromEncodedPath: overviewPoints)
        let overviewPolyline = GMSPolyline(path: overviewPath)
        
        routePolylines.append([polyline, underPolyline, overviewPolyline])
    }
    
}

extension ViewController: GMSMapViewDelegate {
    // Called when user touches to place a marker
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        if routePolylines.count == 0 {
            print("Info: Map: Marker placed at \(coordinate.latitude), \(coordinate.longitude)")
            placeMarker(mapView, at: coordinate)
            getDirections(endCoordinates: coordinate)
        } else {
            var smallestDistances: Array<Double> = []
            for coordinatesForRoute in routeCoordinates {
                smallestDistances.append(coordinatesForRoute.map { Utils.getDistance(between: coordinate, and: $0) }.min()!)
            }

            // 15.60405 is the zoom level at which 50m is appropriate
            // When you get into very zoomed in levels, google maps gets the point at which you clicked slightly wrong lat-long-wise, so if it's under 30m, we assume you tried to click it anyway
            let smallestDistance = smallestDistances.min() ?? -1
            if smallestDistance != -1 && (smallestDistance < 30 || smallestDistance < Double(50 * pow(2, 15.60405-mapView.camera.zoom))) {
                
                let indexesOfSelected = smallestDistances.indices(ofItem: smallestDistance)
                
                if indexesOfSelected.contains(selectedRouteIndex) {
                    // Don't update anything, they might as well have clicked their own line again
                    return
                }
                
                // Might as well choose the first one...
                selectedRouteIndex = indexesOfSelected[0]
                
                for i in 0...routePolylines.count-1 {
                    let selected = i == selectedRouteIndex
                    
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
                print("Info: Map: Marker placed at \(coordinate.latitude), \(coordinate.longitude)")
                placeMarker(mapView, at: coordinate)
                getDirections(endCoordinates: coordinate)
            }
        }
    }
    
    func placeMarker(_ mapView: GMSMapView, at coordinate: CLLocationCoordinate2D) {
        // Resets the selected route index
        selectedRouteIndex = 0
        
        mapView.clear()
        
        marker = GMSMarker(position: coordinate)
        marker.appearAnimation = GMSMarkerAnimation.pop
        marker.map = mapView
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        mapView.selectedMarker = marker
        return true
    }
    
    // called every time a marker info window may need to be created
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        // don't return a view if the marker is just a random regular marker
        if marker.title == nil {
            return nil
        }
        
        let view = UIView(frame: CGRect.init(x: 0, y: 0, width: 200, height: 120))
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 20
        
        let title = UILabel(frame: CGRect.init(x: 8, y: 8, width: view.frame.size.width - 16, height: 15))
        
        title.text = marker.title
        view.addSubview(title)
        
        let desc = UILabel(frame: CGRect.init(x: title.frame.origin.x, y: title.frame.origin.y + title.frame.size.height + 3, width: view.frame.size.width - 16, height: 80))
        
        var descText: String = ""
        marker.snippet!.enumerateLines { line, _ in

            descText = descText + line + "\n"
            
        }
        
        desc.text = descText
        desc.lineBreakMode = .byWordWrapping
        desc.numberOfLines = 5
        desc.font = UIFont.systemFont(ofSize: 12, weight: .light)
        view.addSubview(desc)
        
        return view
    }
 
}


extension ViewController: CLLocationManagerDelegate {
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
        
        // Basically sets reasonable bounds to bias for in the place search
        let autocompleteBiasBounds = GMSCoordinateBounds(coordinate: CLLocationCoordinate2D(latitude: location.coordinate.latitude+0.1, longitude: location.coordinate.longitude+0.1), coordinate: CLLocationCoordinate2D(latitude: location.coordinate.latitude-0.1, longitude: location.coordinate.longitude-0.1))
        
        addressResultsViewController.autocompleteBounds = autocompleteBiasBounds
        
        if currentLocation == nil {
            mapView.animate(to: camera)
        }
        
        currentLocation = location
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Warning: Location: Location access was restricted.")
        case .denied:
            print("Warning: Location: User denied access to location.")
        case .notDetermined:
            print("Warning: Location: Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Info: Location: Location status is OK.")
        }
    }
    
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: Location: \(error)")
    }
}

extension ViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didAutocompleteWith place: GMSPlace) {
        addressSearchController.isActive = false
        
        placeMarker(mapView, at: place.coordinate)
        
        getDirections(endCoordinates: place.coordinate)
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didFailAutocompleteWithError error: Error) {
        print("Error: Autocomplete: \(error.localizedDescription)")
    }
    
    func didRequestAutocompletePredictions(forResultsController resultsController: GMSAutocompleteResultsViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(forResultsController resultsController: GMSAutocompleteResultsViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

extension Array where Element: Equatable {
    func indices(ofItem item: Element) -> [Int] {
        return enumerated().compactMap { $0.element == item ? $0.offset : nil }
    }
}

extension Data {
    private static let hexAlphabet = "0123456789abcdef".unicodeScalars.map { $0 }
    
    public func hexEncodedString() -> String {
        return String(self.reduce(into: "".unicodeScalars, { (result, value) in
            result.append(Data.hexAlphabet[Int(value/16)])
            result.append(Data.hexAlphabet[Int(value%16)])
        }))
    }
}

extension UIView
{
    func addCornerRadiusAnimation(from: CGFloat, to: CGFloat, duration: CFTimeInterval, withTimingFunction timingFunction: CAMediaTimingFunctionName)
    {
        let animation = CABasicAnimation(keyPath:"cornerRadius")
        animation.timingFunction = CAMediaTimingFunction(name: timingFunction)
        animation.fromValue = from
        animation.toValue = to
        animation.duration = duration
        layer.add(animation, forKey: "cornerRadius")
        layer.cornerRadius = to
    }
}
