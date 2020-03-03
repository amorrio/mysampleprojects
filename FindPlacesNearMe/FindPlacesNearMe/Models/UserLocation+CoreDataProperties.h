//
//  UserLocation+CoreDataProperties.h
//  FindPlacesNearMe
//
//  Copyright © 2020 Amor Rio. All rights reserved.
//

#import "UserLocation+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface UserLocation (CoreDataProperties)

+ (NSFetchRequest<UserLocation *> *)fetchRequest;

@property (nonatomic) double latitude;
@property (nonatomic) double longitude;

@end

NS_ASSUME_NONNULL_END
