//
//  ViewController.swift
//  FindPlacesNearMeSwift
//
//  Copyright © 2020 Amor Rio. All rights reserved.
//

import UIKit
import MapKit
import Foundation

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate
{
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var locationPermissionWarning: UILabel!
    
    let annotationViewIdentifier = "MyAnnotation"
    var locationManager : CLLocationManager?
    var currentAnnotations : [MKAnnotation]?
    var currentSearchString : String?
    var dbhelper : CoreDataHelper?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        
        if CLLocationManager.locationServicesEnabled()
        {
            self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager?.requestWhenInUseAuthorization()
            
            if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways ||
                CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse
            {
                //show user location only if location permission is granted
                self.mapView.showsUserLocation = true
            }
        }
        else {
            self.searchBar.isUserInteractionEnabled = false
            self.locationPermissionWarning.isHidden = false
        }
        
        self.mapView.register(MKPinAnnotationView.self, forAnnotationViewWithReuseIdentifier: self.annotationViewIdentifier)
        
        // Do any additional setup after loading the view.
        let delegate : AppDelegate  = UIApplication.shared.delegate as! AppDelegate
        self.dbhelper = CoreDataHelper(context: delegate.persistentContainer.viewContext)
    }
    
    
    ///The refreshButton reperforms the search given the search string that is currently in the search bar
    ///This is in case the user have changed location and wants to update the search result for user's new location
    @IBAction func refreshButtonHit(_ sender: Any) {
        self.performSearch()
    }
    
    ///The resetButton resets the map view to the initial view after a searcj
    ///That is the mapView is zoomed in such a way that all search result pins are visible in the map
    @IBAction func resetButtonHit(_ sender: Any) {
        if let annotations = self.currentAnnotations, annotations.count > 0 {
            
            for annotation in self.mapView.selectedAnnotations{
                self.mapView.deselectAnnotation(annotation, animated: false)
            }
            
            self.mapView.showAnnotations(annotations, animated: true)
        }
    }
    
    //MARK: - MKMapViewDelegate methods
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        var annotationView  = mapView.dequeueReusableAnnotationView(withIdentifier: self.annotationViewIdentifier)
        
        if annotationView == nil{
            annotationView = MKPinAnnotationView(annotation:annotation, reuseIdentifier:self.annotationViewIdentifier)
        }
        else {
            annotationView?.annotation = annotation
        }
        annotationView?.canShowCallout = true
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        self.didEndSearch()
        //enable only the reset b
        self.resetButton.isEnabled = true
    }
    
    //MARK: CLLocationManagerDelegate methods
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse
        {
            self.mapView.showsUserLocation = true
            self.searchBar.isUserInteractionEnabled = true
            self.locationPermissionWarning.isHidden = true
            if self.currentSearchString != nil {
                self.refreshButton.isEnabled = true
            }
                        
            if let annotations = self.currentAnnotations {
                self.mapView.addAnnotations(annotations)
                self.mapView .showAnnotations(annotations, animated: true)
                self.resetButton.isEnabled = true
            }
        }
        else {
            self.mapView.showsUserLocation = false
            self.searchBar.isUserInteractionEnabled = false
            self.refreshButton.isEnabled = false
            self.locationPermissionWarning.isHidden = false
            if let annotations = self.currentAnnotations {
                self.mapView.removeAnnotations(annotations)
                self.resetButton.isEnabled = false
            }
            
    
        }
    }
    
    //MARK: UISearchBarDelegate methods
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        let textToSearch = searchBar.text?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        
        if textToSearch == nil || textToSearch?.count == 0
        {
            self.currentSearchString = nil;
            return
        }
        
        self.currentSearchString = textToSearch
        self.performSearch()
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    //MARK: UtilityMethods
    /**
     Adds the annotation view to the map view
     */
    func addAnnotationToMapView(annotations : [MKAnnotation]?){
        if annotations == nil || annotations?.count == 0
        {
            self.showAlert(message:"Place with name is not found within the area" )
            self.didEndSearch()
            return
        }
        
        self.currentAnnotations = annotations
        self.mapView.addAnnotations(annotations!)
        self.mapView .showAnnotations(annotations!, animated: true)
    }
    
    func performSearch() {
        if let searchString = self.currentSearchString {
            if let annotations = self.currentAnnotations {
                self.mapView.removeAnnotations(annotations)
                self.currentAnnotations = nil
            }
            
            //check first if search result for the given key and location is already saved in database
            //use saved result instead of querying in places demo api if there is saved result
            if let places = self.dbhelper?.placesForSearchResult(searchString: searchString, coordinate:self.mapView.userLocation.coordinate) {
                self.currentAnnotations = self.annotationsForPlaces(places: places)
                self.addAnnotationToMapView(annotations:self.currentAnnotations)
            } else {
                //else perform a new search to the places demo api
                self.refreshButton.isEnabled = false
                self.resetButton.isEnabled = false
                self.searchingIndicator.startAnimating()
                
                self.mapView.isUserInteractionEnabled = false
                self.searchBar.isUserInteractionEnabled = false
                self.performSearchForString(searchString: searchString)
            }
        }
    }
    
    func performSearchForString(searchString : String)
    {
        guard let url = self.placeRestAPIURLForSearchString(searchString: searchString)
            else {
                self.showAlert(message:"Search failed")
                self.didEndSearch()
                return
        }
        
        let coordinate = self.mapView.userLocation.coordinate;
        
        let dataTask = URLSession.shared.dataTask(with: url) { ( data, response, error) in
            
            if  let httpresponse = response as? HTTPURLResponse {
                if httpresponse.statusCode == 200 {
                    do {
                        if let jsonData = data {
                            let result = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:AnyObject]
                            
                            if let annotations = self.annotationsForSearchResult(searchResult: result, searchString: searchString, coordinate: coordinate) {
                                
                                DispatchQueue.main.async {
                                    self.addAnnotationToMapView(annotations: annotations)
                                }
                                return
                            }
                        }
                    }
                    catch { }
                }
            }
            DispatchQueue.main.async {
                self.showAlert(message:"Search failed")
                self.didEndSearch()
            }
        }
        
        dataTask.resume()
    }
    
    func placeRestAPIURLForSearchString(searchString : String) ->URL?
    {
        guard let restAPIURLComponents  = NSURLComponents(string:"https://places.demo.api.here.com/places/v1/discover/search") else {
            return nil
        }
        //add search parameters
        let searchItem = URLQueryItem(name:"q", value: searchString)
        
        //maximum of 10 results
        let searchSize = URLQueryItem(name:"size", value:"10")
        
        let lat = self.mapView.userLocation.coordinate.latitude
        let lon = self.mapView.userLocation.coordinate.longitude
        
        //search area within 5km around the current location
        let areaSpecification = "\(lat),\(lon);r=5000"
        
        let searchArea = URLQueryItem(name:"in", value:areaSpecification)
        
        //authentication credentials for demo account
        let app_id = URLQueryItem(name:"app_id", value:"DemoAppId01082013GAL")
        let app_code = URLQueryItem(name:"app_code", value:"AJKnXv84fjrb0KIHawS0Tg")
        
        restAPIURLComponents.queryItems = [searchItem, searchSize, searchArea, app_id, app_code]
        
        return restAPIURLComponents.url
    }
    
    func annotationsForSearchResult(searchResult : [String: AnyObject]?, searchString : String, coordinate: CLLocationCoordinate2D) -> [MKAnnotation]? {
        
        if let places = self.dbhelper?.placesForSearchResult(searchResult: searchResult, searchString:searchString, coordinate: coordinate)
        {
            guard let annotations = self.annotationsForPlaces(places: places) else {
                return nil
            }
            return annotations
        }
        return nil
    }
    
    func annotationsForPlaces(places : [Place]?) -> [MKAnnotation]?{
        guard let placeArray = places else {
            return nil
        }
        
        var annotations : [MKAnnotation] = []
        for place in placeArray {
            
            var unit = "m"
            var unitDivisor = 1.0
            if place.distance >= 1000.0
            {
                unit = "km"
                unitDivisor = 1000.0
            }
            let distanceString = NSString(format:"%g", place.distance/unitDivisor)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate.latitude = place.latitude
            annotation.coordinate.longitude = place.longitude
            annotation.title =  (place.title ?? "") + ", "  + (place.vicinity ?? "")
            annotation.subtitle = "\(distanceString) \(unit) away"
            
            annotations.append(annotation)
        }
        
        return annotations
    }
    
    func showAlert(message: String){
        let appName : String? = Bundle.main.infoDictionary?["CFBundleDisplayName"]  as? String ?? ""
        
        let alert  = UIAlertController(title:appName, message:message, preferredStyle: UIAlertController.Style.alert)
        
        let action = UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel) { (alertaction) in
            
        }
        
        alert.addAction(action)
        
        self.present(alert, animated: true) {
            //Do nothing
        }
        
    }
    
    func didEndSearch()
    {
        self.searchingIndicator.stopAnimating()
        self.refreshButton.isEnabled = true
        self.mapView.isUserInteractionEnabled = true
        self.searchBar.isUserInteractionEnabled = true
    }
}

