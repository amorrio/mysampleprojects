//
//  Search+CoreDataProperties.m
//  FindPlacesNearMe
//
//  Copyright © 2020 Amor Rio. All rights reserved.
//

#import "Search+CoreDataProperties.h"

@implementation Search (CoreDataProperties)

+ (NSFetchRequest<Search *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Search"];
}

@dynamic searchString;

@end
