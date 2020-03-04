//
//  CoreDataHelper.h
//  FindPlacesNearMe
//
//  Copyright © 2020 Amor Rio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface CoreDataHelper : NSObject
 
/*
    Instantiates and initializes CoreDataHelper instance with NSManagedObjectContext
    @param Instance of NSManagedObjectContext
    @return instance of CoreDataHel[er
 */
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context;


/*
    Returns an array of Place Objects for a given search result
    from places demo API
    @param searchResult
    @return Array of Place objects
 */
- (NSArray *)placesForSearchResult:(NSDictionary *)searchResult searchString:(NSString *)searchString coordinate:(CLLocationCoordinate2D)coordinate;

/*
    Returns an array of Place Objects stored in the data base for the
    a previous search with the same searchString and coordinates
    @param searchString - case insensitive
    @return Array of Place objects
 */
- (NSArray *)placesForSearchString:(NSString *)searchString coordinate:(CLLocationCoordinate2D)coordinate;

@end

NS_ASSUME_NONNULL_END
