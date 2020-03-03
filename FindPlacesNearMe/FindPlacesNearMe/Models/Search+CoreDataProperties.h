//
//  Search+CoreDataProperties.h
//  FindPlacesNearMe
//
//  Copyright © 2020 Amor Rio. All rights reserved.
//

#import "Search+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Search (CoreDataProperties)

+ (NSFetchRequest<Search *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSObject *searchString;

@end

NS_ASSUME_NONNULL_END
