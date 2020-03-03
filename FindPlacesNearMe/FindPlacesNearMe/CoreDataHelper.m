//
//  CoreDataHelper.m
//  FindPlacesNearMe
//
//  Copyright © 2020 Amor Rio. All rights reserved.
//

#import "CoreDataHelper.h"
#import "AppDelegate.h"
#import "Place+CoreDataProperties.h"
#import <CoreData/CoreData.h>


@implementation CoreDataHelper


+ (NSArray *)placesForSearchResult:(NSDictionary *)searchResult searchString:(NSString *)searchString coordinate:(CLLocationCoordinate2D)coordinate
{
    NSDictionary *result = [searchResult objectForKey:@"results"];
    NSArray *placeItems = [result objectForKey:@"items"];
    
    if (placeItems != nil)
    {
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
            
            NSManagedObjectContext * manageObjectContext = [CoreDataHelper getManagedObjectContext];
            
            Place *place =  [NSEntityDescription insertNewObjectForEntityForName:@"Place"
                                                          inManagedObjectContext:manageObjectContext];
            
            if (place)
            {
                place.title = title;
                place.distance = [distance doubleValue];
                place.latitude = [[position objectAtIndex:0] doubleValue];
                place.longitude = [[position objectAtIndex:1] doubleValue];
                place.vicinity = vicinity;
            }
        }
    }
        
        return nil;
}


+ (NSArray *)placesForSearchString:(NSString *)searchString coordinate:(CLLocationCoordinate2D)coordinate
{
    return nil;
}

#pragma mark - private utils

+ (NSManagedObjectContext *)getManagedObjectContext
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    return [[appDelegate persistentContainer] viewContext];
}



@end
