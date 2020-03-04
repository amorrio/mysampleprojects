//
//  UserLocation+CoreDataProperties.h
//  FindPlacesNearMe
//
//  Created by Mobile OS on 4/3/2020.
//  Copyright © 2020 myproject. All rights reserved.
//
//

#import "UserLocation+CoreDataClass.h"
#import "UserLocationSearch+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface UserLocation (CoreDataProperties)

+ (NSFetchRequest<UserLocation *> *)fetchRequest;

@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nullable, nonatomic, retain) NSSet<UserLocationSearch *> *searches;

@end

@interface UserLocation (CoreDataGeneratedAccessors)

- (void)addSearchesObject:(UserLocationSearch *)value;
- (void)removeSearchesObject:(UserLocationSearch *)value;
- (void)addSearches:(NSSet<UserLocationSearch *> *)values;
- (void)removeSearches:(NSSet<UserLocationSearch *> *)values;

@end

NS_ASSUME_NONNULL_END
