//
//  WallObject.m
//  minibattlequest
//
//  Created by Chris on 2017-02-07.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WallObject.h"

#define WALL_DEFAULT_SCALE 50.0f

@interface WallObject()
{
    
    
}
@end

@implementation WallObject

-(id)init
{
    self = [super init];
    self.visible = true;
    self.solid = true;
    self.movable = false;
    self.size = 64.0f;
    self.scale = GLKVector3Make(WALL_DEFAULT_SCALE, WALL_DEFAULT_SCALE, WALL_DEFAULT_SCALE);
    self.modelName = @"crateCube";
    self.textureName = @"crate.jpg";
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
    NSLog(@"Something hit a wall!");
    
    //do nothing for now; the other object will deal with it
    
    
}

@end
