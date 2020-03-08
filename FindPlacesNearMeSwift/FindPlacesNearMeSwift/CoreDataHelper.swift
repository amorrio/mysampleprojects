//
//  CoreDataHelper.swift
//  FindPlacesNearMeSwift
//
//  Copyright © 2020 Amor Rio. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

class CoreDataHelper : NSObject {
    var managedObjectContext : NSManagedObjectContext

    init(context: NSManagedObjectContext){
        self.managedObjectContext = context
    }

    /**
    Returns an array of `Place` objects created by parsing  the `searchResult` dictionary generated from  the JSON response
    to a query of the places .demo.api REST API
    Automatically saves extracted data  to the database

     - Parameter searchResult: The dictionary result from the places.demo.api REST API
     - Parameter searchString: The search key used to get the search result.
     - Parameter coordinate: The  coordinates of the current user location when the search is performed.

     - Returns: An array `Place` objects parsed from the `searchResult`.`nil` if search result is not successfully parsed
     */

    func placesForSearchResult(searchResult: [String:AnyObject]?, searchString: String, coordinate: CLLocationCoordinate2D ) -> [Place]?
    {
        var places : [Place] = []

        guard let result = searchResult?["results"] as? [String:AnyObject] else
        {
            return nil
        }

        guard let placeItems = result["items"] as? [AnyObject] else
        {
            return nil
        }

        let sourceSearch = self.userLocationSearch(searchString: searchString, coordinate:coordinate, createNewIfNone:true)

        for placeItem in placeItems
        {
            guard let placeItemDict  = placeItem as? [String:AnyObject] else {
                continue
            }

            let title = placeItemDict["title"] as? String ?? ""
            var vicinity = placeItemDict["vicinity"] as? String

            if vicinity != nil
            {
                vicinity = vicinity?.replacingOccurrences(of: "<br/>", with: ", ") ?? ""
            }

            guard let distance = placeItemDict["distance"] as? NSNumber else {
                continue
            }

            guard let position =  placeItemDict["position"] as? [NSNumber]
                else {
                    continue
            }

            if position.count < 2 {
                continue
            }

            guard let place = NSEntityDescription.insertNewObject(forEntityName: "Place", into: self.managedObjectContext) as? Place
                else {
                    self.rollbackDatabase()
                    return nil
            }

            place.title = title
            place.vicinity = vicinity
            place.latitude = position[0].doubleValue
            place.longitude = position[1].doubleValue
            place.distance = distance.doubleValue
            place.sourceSearch = sourceSearch

            places.append(place)
        }
        if places.count > 0 {
            self.saveDatabase()
        }
        else {
            self.rollbackDatabase()
        }

        return places
    }

    /**
     Returns an array of `Place` objects that were saved for a specific search key and location

     - Parameter searchString: The search key used to get the search result.
     - Parameter coordinate: The coordinates of the current user location when the search is performed

     - Returns: An array `Place` objects if data is saved for the given search key and location. `nil` otherwise
     */
    func placesForSearchResult(searchString: String, coordinate: CLLocationCoordinate2D ) -> [Place]? {

        if let sourceSearch = self.userLocationSearch(searchString: searchString, coordinate:coordinate, createNewIfNone:false)
        {
            if let places = sourceSearch.places {
                return places.allObjects as? [Place]
            }
        }

        self.rollbackDatabase()
        return nil
    }

    //MARK: Private methods

    private func saveDatabase(){
        if self.managedObjectContext.hasChanges {
            do {
                try self.managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    private func rollbackDatabase(){
        if self.managedObjectContext.hasChanges {
            self.managedObjectContext.rollback()
        }
    }

    private func userLocationSearch(searchString: String, coordinate : CLLocationCoordinate2D, createNewIfNone: Bool) -> UserLocationSearch?
    {
        let search = self.searchForSearchString(searchString: searchString)
        let userLocation = self.userLocationForCoordinate(coordinate: coordinate)

        let fetchRequest : NSFetchRequest<UserLocationSearch> = UserLocationSearch.fetchRequest()
        let predicate = NSPredicate(format:"searchTerm == %@ AND location == %@", search!, userLocation!)
        fetchRequest.predicate = predicate
        var userLocationSearch : UserLocationSearch?
        do {
            let fetchResult =  try self.managedObjectContext.fetch(fetchRequest)
            if fetchResult.count > 0  {
                userLocationSearch = fetchResult[0]
            }
        } catch {

        }

        if userLocationSearch == nil && createNewIfNone {
            userLocationSearch = NSEntityDescription.insertNewObject(forEntityName: "UserLocationSearch", into:self.managedObjectContext) as? UserLocationSearch
            userLocationSearch?.searchTerm = search
            userLocationSearch?.location = userLocation
        }

        return userLocationSearch
    }

    private func searchForSearchString(searchString: String) -> Search?{
        let fetchRequest : NSFetchRequest<Search> = Search.fetchRequest()
        let predicate = NSPredicate(format:"searchString ==[c] %@", searchString)
        fetchRequest.predicate = predicate
        var search : Search?
        do {
            let fetchResult =  try self.managedObjectContext.fetch(fetchRequest)

            if fetchResult.count > 0  {
                search = fetchResult[0]
            }
        } catch {

        }

        if search == nil
        {
            search = NSEntityDescription.insertNewObject(forEntityName: "Search", into: self.managedObjectContext) as? Search
            search?.searchString = searchString
        }
        return search
    }

    private func userLocationForCoordinate(coordinate: CLLocationCoordinate2D) -> UserLocation?{
        let fetchRequest : NSFetchRequest<UserLocation> = UserLocation.fetchRequest()
        let threshold = 0.001
        let predicate = NSPredicate(format:"latitude > %f AND latitude < %f AND longitude > %f AND longitude < %f", coordinate.latitude - threshold,  coordinate.latitude + threshold, coordinate.longitude - threshold, coordinate.longitude + threshold)
        fetchRequest.predicate = predicate
        var userLocation : UserLocation?
        do {
            let fetchResult =  try self.managedObjectContext.fetch(fetchRequest)
            if fetchResult.count > 0  {
                userLocation = fetchResult[0]
            }
        } catch {

        }

        if userLocation == nil
        {
            userLocation = NSEntityDescription.insertNewObject(forEntityName: "UserLocation", into: self.managedObjectContext) as? UserLocation
            userLocation?.latitude = coordinate.latitude
            userLocation?.longitude = coordinate.longitude
        }
        return userLocation
    }

}
