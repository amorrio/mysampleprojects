//
//  UserLocationSearch+CoreDataProperties.swift
//  FindPlacesNearMeSwift
//
//  Copyright © 2020 Amor Rio. All rights reserved.
//

import Foundation
import CoreData


extension UserLocationSearch {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserLocationSearch> {
        return NSFetchRequest<UserLocationSearch>(entityName: "UserLocationSearch")
    }

    @NSManaged public var location: UserLocation?
    @NSManaged public var places: NSSet?
    @NSManaged public var searchTerm: Search?

}

// MARK: Generated accessors for places
extension UserLocationSearch {

    @objc(addPlacesObject:)
    @NSManaged public func addToPlaces(_ value: Place)

    @objc(removePlacesObject:)
    @NSManaged public func removeFromPlaces(_ value: Place)

    @objc(addPlaces:)
    @NSManaged public func addToPlaces(_ values: NSSet)

    @objc(removePlaces:)
    @NSManaged public func removeFromPlaces(_ values: NSSet)

}
