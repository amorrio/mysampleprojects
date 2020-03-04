//
//  CoreDataHelper.m
//  FindPlacesNearMe
//
//  Copyright © 2020 Amor Rio. All rights reserved.
//

#import "CoreDataHelper.h"
#import "AppDelegate.h"
#import "Place+CoreDataProperties.h"
#import "UserLocationSearch+CoreDataProperties.h"
#import "Search+CoreDataProperties.h"
#import "UserLocation+CoreDataProperties.h"

@interface CoreDataHelper ()

@property (nonatomic, strong) NSManagedObjectContext *manageObjectContext;

@end


@implementation CoreDataHelper

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        self.manageObjectContext = context;
    }
    return self;
}

- (NSArray *)placesForSearchResult:(NSDictionary *)searchResult searchString:(NSString *)searchString coordinate:(CLLocationCoordinate2D)coordinate
{
    NSDictionary *result = [searchResult objectForKey:@"results"];
    NSArray *placeItems = [result objectForKey:@"items"];
    
    if (placeItems != nil && [placeItems count] > 0)
    {
        NSMutableArray *places = [[NSMutableArray alloc] init];
        UserLocationSearch *userLocationSearch = [self userLocationSearchForSearchString:searchString coordinate:coordinate createNewIfNone:YES];

        for (NSDictionary *placeItem in placeItems)
        {
            NSString *title  = [placeItem objectForKey:@"title"];
            NSString *vicinity = [placeItem objectForKey:@"vicinity"];
            
            if (vicinity != nil)
            {
                vicinity = [vicinity stringByReplacingOccurrencesOfString:@"<br/>" withString:@", "];
            }
           
            NSArray *position =[placeItem objectForKey:@"position"];
            CLLocationCoordinate2D coordinate;
            coordinate.latitude = [[position objectAtIndex:0] doubleValue];
            coordinate.longitude = [[position objectAtIndex:1] doubleValue];
            
            NSNumber *distance = [placeItem objectForKey:@"distance"];
            Place *place =  [NSEntityDescription insertNewObjectForEntityForName:@"Place"
                                                          inManagedObjectContext:self.manageObjectContext];
            
            if (place)
            {
                place.title = title;
                place.distance = [distance doubleValue];
                place.latitude = [[position objectAtIndex:0] doubleValue];
                place.longitude = [[position objectAtIndex:1] doubleValue];
                place.vicinity = vicinity;
                place.sourceSearch = userLocationSearch;
            }
            [places addObject:place];
        }
        [self saveDatabase];
        return places;
    }
    
    return nil;
}


- (NSArray *)placesForSearchString:(NSString *)searchString coordinate:(CLLocationCoordinate2D)coordinate
{
    UserLocationSearch *userLocationSearch = [self userLocationSearchForSearchString:searchString coordinate:coordinate createNewIfNone:NO];
    
    if (userLocationSearch != nil)
    {
        return [userLocationSearch.places allObjects];
    }
    
    //rollback since it might have created new user location and search term
    [self rollBackDatabaseChanges];
    return nil;
}

#pragma mark - private utils

- (void)saveDatabase
{
    NSManagedObjectContext *context = self.manageObjectContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
    }
}

- (void)rollBackDatabaseChanges
{
    NSManagedObjectContext *context = self.manageObjectContext;
    if ([context hasChanges])
    {
        [context rollback];
    }
}

- (UserLocationSearch *)userLocationSearchForSearchString:searchString coordinate: (CLLocationCoordinate2D)coordinate createNewIfNone:(BOOL)createNewIfNone
{
    Search *search = [self searchForSearchString:searchString];
    UserLocation *userLocation = [self userLocatinForCoordinate:coordinate];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"searchTerm == %@ AND location == %@", search, userLocation];
    NSFetchRequest *fetchRequest = [UserLocationSearch fetchRequest];
    [fetchRequest setPredicate:predicate];
    UserLocationSearch *userLocationSearch = nil;
    NSManagedObjectContext *context = self.manageObjectContext;
    NSError *error;
    NSArray *fetchResult = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchResult && [fetchResult count] > 0){
        userLocationSearch = [fetchResult objectAtIndex:0];
    }

    if (userLocationSearch == nil && createNewIfNone)
    {
        userLocationSearch = [NSEntityDescription insertNewObjectForEntityForName:@"UserLocationSearch"
                                               inManagedObjectContext:context];
        userLocationSearch.searchTerm = search;
        userLocationSearch.location = userLocation;
    }
  
    return userLocationSearch;
}

- (Search *)searchForSearchString:(NSString *)searchString
{
    NSFetchRequest *fetchRequest = [Search fetchRequest];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"searchString ==[c] %@", searchString];
    [fetchRequest setPredicate:predicate];
    
    NSError *error;
    Search *search = nil;
    
    NSArray *fetchResult = [self.manageObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchResult && [fetchResult count] > 0){
        search = [fetchResult objectAtIndex:0];
    }
    
    if (search == nil)
    {
        search = [NSEntityDescription insertNewObjectForEntityForName:@"Search"
                                      inManagedObjectContext:self.manageObjectContext];
        search.searchString = searchString;
    }
    return search;
}

- (UserLocation *)userLocatinForCoordinate:(CLLocationCoordinate2D)coordinate
{
    NSFetchRequest *fetchRequest = [UserLocation fetchRequest];
    double epsilon = 0.001; //third decimal is accuracy by the ~100m in latitude and longitude
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"latitude > %f AND latitude < %f AND longitude > %f AND longitude < %f", coordinate.latitude - epsilon,  coordinate.latitude + epsilon, coordinate.longitude - epsilon, coordinate.longitude + epsilon];
    [fetchRequest setPredicate:predicate];
    
    NSManagedObjectContext *context = self.manageObjectContext;
    NSError *error;
    UserLocation *userLocation = nil;
    
    NSArray *fetchResult = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchResult && [fetchResult count] > 0)
    {
        userLocation = [fetchResult objectAtIndex:0];
    }
    
    if (userLocation == nil)
    {
        userLocation = [NSEntityDescription insertNewObjectForEntityForName:@"UserLocation"
                                               inManagedObjectContext:context];
        userLocation.latitude = coordinate.latitude;
        userLocation.longitude = coordinate.longitude;
    }
    return userLocation;
}

@end
