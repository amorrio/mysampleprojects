//
//  Search+CoreDataProperties.h
//  FindPlacesNearMe
//
//  Created by Mobile OS on 4/3/2020.
//  Copyright © 2020 myproject. All rights reserved.
//
//

#import "Search+CoreDataClass.h"

@class UserLocationSearch;


NS_ASSUME_NONNULL_BEGIN

@interface Search (CoreDataProperties)

+ (NSFetchRequest<Search *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *searchString;
@property (nullable, nonatomic, retain) NSSet<UserLocationSearch *> *searches;

@end

@interface Search (CoreDataGeneratedAccessors)

- (void)addSearchesObject:(UserLocationSearch *)value;
- (void)removeSearchesObject:(UserLocationSearch *)value;
- (void)addSearches:(NSSet<UserLocationSearch *> *)values;
- (void)removeSearches:(NSSet<UserLocationSearch *> *)values;

@end

NS_ASSUME_NONNULL_END
