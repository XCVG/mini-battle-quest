//
//  LeaderboardScore+CoreDataProperties.h
//  minibattlequest
//
//  Created by Erick Fernandez de Arteaga on 2017-02-15.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#import "LeaderboardScore+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface LeaderboardScore (CoreDataProperties)

+ (NSFetchRequest<LeaderboardScore *> *)fetchRequest;

@property (nonatomic) int32_t score;

@end

NS_ASSUME_NONNULL_END
