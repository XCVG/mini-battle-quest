//
//  LeaderboardScore+CoreDataProperties.m
//  minibattlequest
//
//  Created by Erick Fernandez de Arteaga on 2017-02-15.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#import "LeaderboardScore+CoreDataProperties.h"

@implementation LeaderboardScore (CoreDataProperties)

+ (NSFetchRequest<LeaderboardScore *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"LeaderboardScore"];
}

@dynamic score;

@end
