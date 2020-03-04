//
//  Search+CoreDataProperties.m
//  FindPlacesNearMe
//
//  Created by Mobile OS on 4/3/2020.
//  Copyright © 2020 myproject. All rights reserved.
//
//

#import "Search+CoreDataProperties.h"

@implementation Search (CoreDataProperties)

+ (NSFetchRequest<Search *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Search"];
}

@dynamic searchString;
@dynamic searches;

@end
