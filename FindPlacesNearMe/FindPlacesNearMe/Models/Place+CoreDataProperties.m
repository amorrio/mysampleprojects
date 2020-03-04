//
//  Place+CoreDataProperties.m
//  FindPlacesNearMe
//
//  Created by Mobile OS on 4/3/2020.
//  Copyright © 2020 myproject. All rights reserved.
//
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
