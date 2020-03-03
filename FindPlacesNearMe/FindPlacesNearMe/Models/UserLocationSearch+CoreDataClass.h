//
//  UserLocationSearch+CoreDataClass.h
//  FindPlacesNearMe
//
//  Copyright © 2020 Amor Rio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Place, Search, UserLocation;

NS_ASSUME_NONNULL_BEGIN

@interface UserLocationSearch : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "UserLocationSearch+CoreDataProperties.h"
