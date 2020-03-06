//
//  UserLocation+CoreDataProperties.swift
//  FindPlacesNearMeSwift
//
//  Copyright © 2020 Amor Rio. All rights reserved.
//

import Foundation
import CoreData


extension UserLocation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserLocation> {
        return NSFetchRequest<UserLocation>(entityName: "UserLocation")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var searches: NSSet?

}

// MARK: Generated accessors for searches
extension UserLocation {

    @objc(addSearchesObject:)
    @NSManaged public func addToSearches(_ value: UserLocationSearch)

    @objc(removeSearchesObject:)
    @NSManaged public func removeFromSearches(_ value: UserLocationSearch)

    @objc(addSearches:)
    @NSManaged public func addToSearches(_ values: NSSet)

    @objc(removeSearches:)
    @NSManaged public func removeFromSearches(_ values: NSSet)

}
