//
//  UserLocationSearch+CoreDataProperties.h
//  FindPlacesNearMe
//
//  Created by Mobile OS on 4/3/2020.
//  Copyright © 2020 myproject. All rights reserved.
//
//

#import "UserLocationSearch+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface UserLocationSearch (CoreDataProperties)

+ (NSFetchRequest<UserLocationSearch *> *)fetchRequest;

@property (nullable, nonatomic, retain) UserLocation *location;
@property (nullable, nonatomic, retain) NSSet<Place *> *places;
@property (nullable, nonatomic, retain) Search *searchTerm;

@end

@interface UserLocationSearch (CoreDataGeneratedAccessors)

- (void)addPlacesObject:(Place *)value;
- (void)removePlacesObject:(Place *)value;
- (void)addPlaces:(NSSet<Place *> *)values;
- (void)removePlaces:(NSSet<Place *> *)values;

@end

NS_ASSUME_NONNULL_END
