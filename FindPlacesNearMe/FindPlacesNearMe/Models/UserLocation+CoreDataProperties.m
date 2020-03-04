//
//  UserLocation+CoreDataProperties.m
//  FindPlacesNearMe
//
//  Created by Mobile OS on 4/3/2020.
//  Copyright © 2020 myproject. All rights reserved.
//
//

#import "UserLocation+CoreDataProperties.h"

@implementation UserLocation (CoreDataProperties)

+ (NSFetchRequest<UserLocation *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"UserLocation"];
}

@dynamic latitude;
@dynamic longitude;
@dynamic searches;

@end
