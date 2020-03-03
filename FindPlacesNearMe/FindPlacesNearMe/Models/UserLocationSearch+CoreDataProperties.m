//
//  UserLocationSearch+CoreDataProperties.m
//  FindPlacesNearMe
//
//  Copyright © 2020 Amor Rio. All rights reserved.
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
