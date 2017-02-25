//
//  EnemyObject.m
//  minibattlequest
//
//  Created by Chris on 2017-01-31.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyObject.h"
#import "ArrowObject.h"

@interface EnemyObject()
{
    
    
}
@end

@implementation EnemyObject

//we should override these (are they virtual by default like Java or not like C++?)
-(id)init
{
    self = [super init];
    self.solid = true;
    self.visible = true;
    self.movable = true;
    return self;
}

-(MBQObjectUpdateOut)update:(MBQObjectUpdateIn*)data
{
    MBQObjectUpdateOut outData = [super update:data];
    
    return outData;
}

//may need to rethink this; pass information back to scene to render
-(MBQObjectDisplayOut)display:(MBQObjectDisplayIn*)data
{
    MBQObjectDisplayOut outData;
    
    return outData;
}

-(void)onCollision:(GameObject*)otherObject
{
    NSLog(@"Something Hit an Enemy!");
    if ([otherObject isKindOfClass:[ArrowObject class]])
    {
        //lose health points
        ArrowObject * myArrow = (ArrowObject*)otherObject;
        [self takeDamage:myArrow.damage];
    }
}

-(void)takeDamage:(float)damage
{
    self.health -= damage;
    NSLog(@"Ouch! Health: %f",self.health);
    
    if (self.health <= 0)
    {
        NSLog(@"I dun gone died!");
        [self destroy];
    }
}

@end
