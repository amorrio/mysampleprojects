//
//  Search+CoreDataProperties.swift
//  FindPlacesNearMeSwift
//
//  Copyright © 2020 Amor Rio. All rights reserved.
//

import Foundation
import CoreData


extension Search {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Search> {
        return NSFetchRequest<Search>(entityName: "Search")
    }

    @NSManaged public var searchString: String?
    @NSManaged public var searches: NSSet?

}

// MARK: Generated accessors for searches
extension Search {

    @objc(addSearchesObject:)
    @NSManaged public func addToSearches(_ value: UserLocationSearch)

    @objc(removeSearchesObject:)
    @NSManaged public func removeFromSearches(_ value: UserLocationSearch)

    @objc(addSearches:)
    @NSManaged public func addToSearches(_ values: NSSet)

    @objc(removeSearches:)
    @NSManaged public func removeFromSearches(_ values: NSSet)

}
