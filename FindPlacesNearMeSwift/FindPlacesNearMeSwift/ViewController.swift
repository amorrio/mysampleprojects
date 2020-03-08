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

    ///The resetButton resets the map view to the initial view after a search
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
        //show end search state after the annotations are already shown in view
        self.didEndSearch()
        //enable only the reset button if there are annotations shown
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
    Adds array of annotations to the map view
    Sets the map to show all the annotations added

		-Parameter annotations: array of annotations to add to the mapView
    */
    func addAnnotationToMapView(annotations : [MKAnnotation]){
        self.currentAnnotations = annotations
        self.mapView.addAnnotations(annotations)
        self.mapView .showAnnotations(annotations, animated: true)
    }

    /**
    Performs the search for the current search string and show the result
    in the map
    It first tries to find if there is already a cached search result for the
    given search string in the current user location in the database.
    If there is no cached result, triggers the search using the places demo API
    */
    func performSearch() {
        if let searchString = self.currentSearchString {
            if let annotations = self.currentAnnotations {
                self.mapView.removeAnnotations(annotations)
                self.currentAnnotations = nil
            }

            //check first if search result for the given key and location is already saved in database
            //use saved result instead of querying in places demo api if there is saved result
            if let places = self.dbhelper?.placesForSearchResult(searchString: searchString, coordinate:self.mapView.userLocation.coordinate) {
                if let annotations =  self.annotationsForPlaces(places: places){
                    self.currentAnnotations = annotations
                    self.addAnnotationToMapView(annotations:annotations)
                }
            } else {
                //else perform a new search to the places demo api
                //disable the buttons
                self.refreshButton.isEnabled = false
                self.resetButton.isEnabled = false
                //start searching indicator
                self.searchingIndicator.startAnimating()
                //disable user interaction for mapView and searchBar
                self.mapView.isUserInteractionEnabled = false
                self.searchBar.isUserInteractionEnabled = false

                self.performSearchForString(searchString: searchString)
            }
        }
    }

    /**
    Performs the search using the places demo API  for the given searchString

    - Parameter searchString: place identifier to be searched
    around the current user location
    */
    func performSearchForString(searchString : String)
    {
        //get user coordinate
        let coordinate = self.mapView.userLocation.coordinate;

        //form the REST API url for the places demo API
        guard let url = self.placeRestAPIURLForSearchString(searchString: searchString, coordinate: coordinate)
            else {
              //if search url is not properly formed, show alert that search has failed
              //and end search
                self.showAlert(message:"Search failed")
                self.didEndSearch()
                return
        }

        //perform search via REST API using place demo API
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in

            if  let httpresponse = response as? HTTPURLResponse {
                if httpresponse.statusCode == 200 {
                    do {
                        if let jsonData = data {
                            let result = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:AnyObject]

                            if let annotations = self.annotationsForSearchResult(searchResult: result, searchString: searchString, coordinate: coordinate) {

                                DispatchQueue.main.async {
                                    if annotations.count == 0
                                    {
                                        self.showAlert(message:"Place with name is not found within the area" )
                                        self.didEndSearch()
                                        return
                                    }
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

    /**
    Form the REST API URL using the places demo API  for the given searchString
    - Parameter searchString: place identifier to be searched
    around the current user location

      - Parameter coordinate: coordinates for the current user location
    */
    func placeRestAPIURLForSearchString(searchString : String, coordinate: CLLocationCoordinate2D) ->URL?
    {
        guard let restAPIURLComponents  = NSURLComponents(string:"https://places.demo.api.here.com/places/v1/discover/search") else {
            return nil
        }
        //add search parameters
        let searchItem = URLQueryItem(name:"q", value: searchString)

        //maximum of 10 results
        let searchSize = URLQueryItem(name:"size", value:"10")

        let lat = coordinate.latitude
        let lon = coordinate.longitude

        //search area within 5km around the current location
        let areaSpecification = "\(lat),\(lon);r=5000"

        let searchArea = URLQueryItem(name:"in", value:areaSpecification)

        //authentication credentials for demo account
        let app_id = URLQueryItem(name:"app_id", value:"DemoAppId01082013GAL")
        let app_code = URLQueryItem(name:"app_code", value:"AJKnXv84fjrb0KIHawS0Tg")

        restAPIURLComponents.queryItems = [searchItem, searchSize, searchArea, app_id, app_code]

        return restAPIURLComponents.url
    }

    /**
    Creates an array of annotations given the search result from the places demo API
    - Parameter searchResult: dictionary form of the JSON result of the query to
    the places demo API

    - Parameter searchString: place identifier searched
    - Parameter coordinate: ser location searched

    - Returns: Array of annotations if data of surrounding places is extracted from
    the searchResult, nil otherwise
    */
    func annotationsForSearchResult(searchResult : [String: AnyObject]?, searchString : String, coordinate: CLLocationCoordinate2D) -> [MKAnnotation]? {
        //parse search result into an array of Place objects
        if let places = self.dbhelper?.placesForSearchResult(searchResult: searchResult, searchString:searchString, coordinate: coordinate)
        {
          //create annotations from array of place objects
            return self.annotationsForPlaces(places: places)
        }
        return nil
    }

    /**
    Creates an array of annotations given an array of Place objects

    - Parameter places: array of place objects

    - Returns: Array of annotations
    */
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

    /**
    Shows an alert for the given alert message

    - Parameter message: message to display in alert
    */
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

    /**
    Sets the state of the UI when a search has ended.
    * Stop searching searchingIndicator
    * enable refreshButton
    * enable user interaction for mapView and searchBar
    */
    func didEndSearch()
    {
        self.searchingIndicator.stopAnimating()
        self.refreshButton.isEnabled = true
        self.mapView.isUserInteractionEnabled = true
        self.searchBar.isUserInteractionEnabled = true
    }
}
