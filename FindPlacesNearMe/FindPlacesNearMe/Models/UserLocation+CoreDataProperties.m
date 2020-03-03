//
//  UserLocation+CoreDataProperties.m
//  FindPlacesNearMe
//
//  Copyright © 2020 Amor Rio. All rights reserved.
//

#import "UserLocation+CoreDataProperties.h"

@implementation UserLocation (CoreDataProperties)

+ (NSFetchRequest<UserLocation *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"UserLocation"];
}

@dynamic latitude;
@dynamic longitude;

@end
