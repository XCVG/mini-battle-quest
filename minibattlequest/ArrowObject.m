//
//  ArrowObject.m
//  minibattlequest
//
//  Created by Chris on 2017-02-22.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ArrowObject.h"

@interface ArrowObject()
{
    
    
}
@end

@implementation ArrowObject
{
    float _elapsed;
}

-(id)init
{
    self = [super init];
    
    self.visible = true;
    self.solid = true;
    self.movable = true;
    self.size = 32.0f;
    self.damage = 20;
    
    return self;
}

-(MBQObjectUpdateOut)update:(MBQObjectUpdateIn*)data
{
    MBQObjectUpdateOut outData = [super update:data];
    
    
    return outData;
}

-(MBQObjectDisplayOut)display:(MBQObjectDisplayIn*)data
{
    MBQObjectDisplayOut outData;
    
    return outData;
}

-(void)onCollision:(GameObject*)otherObject
{
    NSLog(@"Arrow Hit an Object!");
    [self destroy];
}

@end
