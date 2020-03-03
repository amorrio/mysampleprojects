//
//  Place+CoreDataProperties.m
//  FindPlacesNearMe
//
//  Copyright © 2020 Amor Rio. All rights reserved.
//

#import "Place+CoreDataProperties.h"

@implementation Place (CoreDataProperties)

+ (NSFetchRequest<Place *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Place"];
}

@dynamic distance;
@dynamic latitude;
@dynamic longitude;
@dynamic title;
@dynamic vicinity;
@dynamic sourceSearch;

@end
