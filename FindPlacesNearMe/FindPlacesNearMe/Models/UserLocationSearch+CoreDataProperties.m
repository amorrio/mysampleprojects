//
//  UserLocationSearch+CoreDataProperties.m
//  FindPlacesNearMe
//
//  Created by Mobile OS on 4/3/2020.
//  Copyright © 2020 myproject. All rights reserved.
//
//

#import "UserLocationSearch+CoreDataProperties.h"

@implementation UserLocationSearch (CoreDataProperties)

+ (NSFetchRequest<UserLocationSearch *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"UserLocationSearch"];
}

@dynamic location;
@dynamic places;
@dynamic searchTerm;

@end
