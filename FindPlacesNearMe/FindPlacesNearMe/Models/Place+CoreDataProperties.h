//
//  Place+CoreDataProperties.h
//  FindPlacesNearMe
//
//  Copyright © 2020 Amor Rio. All rights reserved.
//

#import "Place+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Place (CoreDataProperties)

+ (NSFetchRequest<Place *> *)fetchRequest;

@property (nonatomic) double distance;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nullable, nonatomic, copy) NSString *title;
@property (nullable, nonatomic, copy) NSString *vicinity;
@property (nullable, nonatomic, retain) UserLocationSearch *sourceSearch;

@end

NS_ASSUME_NONNULL_END
