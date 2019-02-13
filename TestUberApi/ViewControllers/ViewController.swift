//
//  ViewController.swift
//  TestUberApi
//
//  Created by Juan David Cardona on 2/12/19.
//  Copyright © 2019 Juan David Cardona. All rights reserved.
//

import UIKit
import MapKit
import UberRides
import UberCore

class ViewController: UIViewController {

    lazy var searchCompleter: MKLocalSearchCompleter = {
        let sC = MKLocalSearchCompleter()
        sC.delegate = self
        return sC
    }()
    
    var searchSource: [MKLocalSearchCompletion]?
    
    
    @IBOutlet weak var swipeView: UIView!
    @IBOutlet weak var marketCenter: UIImageView!
    @IBOutlet weak var viewContentSearch: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var searchBarAddress: UISearchBar!
    @IBOutlet weak var constraintSearchView: NSLayoutConstraint!
    
    var isSelectedRoute = false
    var geoCoder : CLGeocoder!
    var locationManager : CLLocationManager!
    var previusAddress : String!
    var userLocation : CLLocation!
    var lastLocationSelected : CLLocation!

    let ridesClient = RidesClient()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupViews()
        
    }
    
    func setupRide(end : CLLocationCoordinate2D){
        //Set constraints
//        NetworServices.shared.fetchEstimates(start: lastLocationSelected.coordinate, end: end) { (estimate, err) in
//            print(err ?? "")
//        }
       
        Configuration.shared.isSandbox = true
        
        let ridesClient = RidesClient()
        let pickupLocation = lastLocationSelected
        let dropoffLocation = CLLocation(coordinate: end, altitude: lastLocationSelected.altitude, horizontalAccuracy: lastLocationSelected.horizontalAccuracy, verticalAccuracy: lastLocationSelected.verticalAccuracy, course: lastLocationSelected.course, speed: lastLocationSelected.speed, timestamp: Date())
        //let pickupLocation = CLLocation(latitude: 37.787654, longitude: -122.402760)
        //let dropoffLocation = CLLocation(latitude: 37.775200, longitude: -122.417587)
        let builder = RideParametersBuilder()
        builder.pickupLocation = pickupLocation
        builder.dropoffLocation = dropoffLocation
        
        ridesClient.fetchCurrentRide { ride, response in
            //print("--response status service" + "\(ride?.status)")
        }
        
        
        ridesClient.fetchProducts(pickupLocation: pickupLocation!) { products, response in
            
            guard let uberX = products.filter({$0.productGroup == .uberX}).first else {
                return
            }
            
            //builder.productID = uberX.productID
            ridesClient.fetchRideRequestEstimate(parameters: builder.build(), completion: { rideEstimate, response in
                guard let rideEstimate = rideEstimate else {
                    return
                }
                
                builder.upfrontFare = rideEstimate.fare
                ridesClient.requestRide(parameters: builder.build(), completion: { ride, response in
                    guard let ride = ride else {
                        self.showAlertService(message : response.error?.errors![0].title ?? "")
                        return
                    }
                    print("se envío la request del servicio")
                    self.showAlertService(message : "Your service was send correctly, to \(ride.driver?.name ?? "")")
                })
            })
            
        }
        
       
    }
    
    func setupViews(){
    
        tableView.delegate = self
        tableView.dataSource = self
        searchBarAddress.delegate = self
        map.delegate = self
        map.mapType = .standard
        map.isZoomEnabled = true
        map.isScrollEnabled = true
        map.showsUserLocation = true
        map.isPitchEnabled = true
        map.showsCompass = true
        geoCoder = CLGeocoder()
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.requestLocation()
        
        viewContentSearch.layer.shadowColor = UIColor.black.cgColor;
        viewContentSearch.layer.shadowOffset = CGSize.zero
        viewContentSearch.layer.shadowRadius = 5.0;
        viewContentSearch.layer.shadowOpacity = 0.5;
        viewContentSearch.backgroundColor = UIColor.white
        viewContentSearch.layer.cornerRadius = 10
        swipeView.layer.cornerRadius = 2
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(upView))
        swipeUp.direction = .up
        self.viewContentSearch.addGestureRecognizer(swipeUp)
        let swipedown = UISwipeGestureRecognizer(target: self, action: #selector(downView))
        swipedown.direction = .down
        self.viewContentSearch.addGestureRecognizer(swipedown)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveKeyboardNotificationObserver(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveKeyboardNotificationObserver(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

    }
    
    @objc func didReceiveKeyboardNotificationObserver(_ notification: Notification) {
        let userInfo = notification.userInfo
        let keyboardFrame = (userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        switch notification.name {
        case UIResponder.keyboardWillShowNotification:
            
            let sizeFrame : CGFloat =  (keyboardFrame.size.height)
            self.constraintSearchView.constant = sizeFrame
            break
        // keyboardWillShowNotification
        case UIResponder.keyboardWillHideNotification:
            self.constraintSearchView.constant = 0
            break
        // keyboardWillHideNotification
        default:
            break
        }
    }
    
    @objc func upView(gesture: UITapGestureRecognizer) {
        self.constraintSearchView.constant = 0
        self.searchBarAddress.isHidden = false
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func downView(gesture: UITapGestureRecognizer) {
        self.constraintSearchView.constant = -self.viewContentSearch.frame.height + 70
        self.searchBarAddress.isHidden = true
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    func swipeViewDown(){
        self.constraintSearchView.constant = -self.viewContentSearch.frame.height + 70
        self.searchBarAddress.isHidden = true
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func currentLocation(_ sender: Any) {
        self.viewContentSearch.isHidden = false
        clearMapAndMarker()
        goToCurrentLocation()
    }
    
    func invalidateCentralMarker(){
        self.isSelectedRoute = true
        let allAnnotations = self.map.annotations
        self.map.removeAnnotations(allAnnotations)
        self.marketCenter.isHidden = true
        self.map.delegate = nil
    }
    
    func drawRute( location : CLLocationCoordinate2D){
        self.invalidateCentralMarker()
        self.map.centerCoordinate = location

        self.swipeViewDown()
        if(lastLocationSelected != nil){
            self.showRouteOnMap(pickupCoordinate: lastLocationSelected.coordinate, destinationCoordinate: location)
        }else{
            self.showRouteOnMap(pickupCoordinate: userLocation.coordinate, destinationCoordinate: location)
        }
        
    }
    
    func clearMapAndMarker(){
        self.isSelectedRoute = false
        let allAnnotations = self.map.annotations
        self.map.removeAnnotations(allAnnotations)
        self.marketCenter.isHidden = false
        let allOverlays = map.overlays
        map.removeOverlays(allOverlays)
        self.map.delegate = self
        self.lastLocationSelected = userLocation
    }
    
    func goToCurrentLocation(){
        if(userLocation != nil){
            let location = userLocation
            self.map.centerCoordinate = location!.coordinate
            let reg = MKCoordinateRegion(center: location!.coordinate, latitudinalMeters: 1500, longitudinalMeters: 1500)
            userLocation = location
            self.map.setRegion(reg, animated: true)
            self.geoCode(location: location!)
        }
       
    }
    
    func geoCode( location : CLLocation ){
        
        geoCoder.cancelGeocode()
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (data, error) -> Void in
            guard let placeMarks = data as [CLPlacemark]! else {
                return
            }
            let loc: CLPlacemark = placeMarks[0]
            let addressDict : [NSString:NSObject] = loc.addressDictionary as! [NSString: NSObject]
            let addrList = addressDict["FormattedAddressLines"] as! [String]
            let address = self.getDirection(array: addrList)

            self.address.text = address
            self.previusAddress = address
        })
        
    }
    
    func getDirection(array : [String]) -> String {
        let stringArray = array.map{ String($0) }
        return stringArray.joined(separator: ",")
    }
    
    func showRouteOnMap(pickupCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {
        
        self.setupRide( end : destinationCoordinate)

        map.delegate = self

        let sourcePlacemark = MKPlacemark(coordinate: pickupCoordinate, addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        let sourceAnnotation = MKPointAnnotation()
        
        if let location = sourcePlacemark.location {
            sourceAnnotation.title = "Source"
            sourceAnnotation.coordinate = location.coordinate

        }
        
        let destinationAnnotation = MKPointAnnotation()
        
        if let location = destinationPlacemark.location {
            destinationAnnotation.title = "Destination"
            destinationAnnotation.coordinate = location.coordinate

        }

    self.map.showAnnotations([sourceAnnotation,destinationAnnotation], animated: true )
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile
        
        // Calculate the direction
        let directions = MKDirections(request: directionRequest)
        
        directions.calculate {
            (response, error) -> Void in
            
            guard let response = response else {
                if let error = error {
                    print("Error: \(error)")
                }
                
                return
            }
            
            let route = response.routes[0]
            
            self.map.addOverlay((route.polyline), level: MKOverlayLevel.aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            self.map.setRegion(MKCoordinateRegion(rect), animated: true)

        }
        
    }
    
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    

}


extension ViewController : CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
     
        let location: CLLocation = locations.first!
        self.map.centerCoordinate = location.coordinate
        let reg = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1500, longitudinalMeters: 1500)
        userLocation = location
        self.map.setRegion(reg, animated: true)
        self.geoCode(location: location)
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
}

extension ViewController : MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
       
        if(self.isSelectedRoute == false){
            let location = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
            lastLocationSelected = location
            geoCode(location: location)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor(red: 17.0/255.0, green: 147.0/255.0, blue: 255.0/255.0, alpha: 1)
        renderer.lineWidth = 5.0
        
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if (annotation is MKUserLocation) {
            return nil
        }
        if annotation.title == "Destination"{
            let reuseId = "pin"
            
            var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
            
            if pinView == nil {
                pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                pinView?.image = UIImage(named: "icons_llegada")
                pinView?.canShowCallout = false
                pinView?.isDraggable = true
            }
            else {
                pinView!.annotation = annotation
            }
            return pinView
            
        }else{
            return nil
        }
    }
    
    func showAlertService(message : String?){
        
        let showAlert = UIAlertController(title: "Information" , message : message, preferredStyle: .alert)
        showAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
        }))
        self.present(showAlert, animated: true, completion: nil)
        
    }

    
}

extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        //change searchCompleter depends on searchBar's text
        if !searchText.isEmpty {
            searchCompleter.queryFragment = searchText
        }else{
            self.searchSource = []
            self.tableView.reloadData()
        }
    }
}

extension ViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer:
        MKLocalSearchCompleter) {
        
       self.searchSource = completer.results
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

extension ViewController : UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchSource?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let title = self.searchSource![indexPath.row].title
        let subtitle = self.searchSource![indexPath.row].subtitle
        
        let cell = UITableViewCell(style: .subtitle , reuseIdentifier: nil)
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = subtitle

        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchBarAddress.resignFirstResponder()
        self.isSelectedRoute = true
        let title = searchSource![indexPath.row].title
        
        let request: MKLocalSearch.Request = MKLocalSearch.Request()
        request.naturalLanguageQuery = title
        let search = MKLocalSearch(request: request)
        search.start {
            (response, error) -> Void in
            
            if response == nil{
                return
            }
            
            let locationDest = CLLocationCoordinate2D(latitude: response!.mapItems[0].placemark.coordinate.latitude, longitude: response!.mapItems[0].placemark.coordinate.longitude)
            
            self.drawRute(location: locationDest)
        }
        
    }
    
}
