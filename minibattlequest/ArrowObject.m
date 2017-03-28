//
//  ArrowObject.m
//  minibattlequest
//
//  Created by Chris on 2017-02-22.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ArrowObject.h"

#define ARROW_DEFAULT_SCALE 35.0f


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
    self.modelRotation = GLKVector3Make(0.0f, 0.0f, 1.5708f);
    self.scale = GLKVector3Make(ARROW_DEFAULT_SCALE, ARROW_DEFAULT_SCALE, ARROW_DEFAULT_SCALE);
    self.damage = 40;
    
//    self.modelName = @"Arrow";
//    self.textureName = @"EnemyWizard_Texture.png";
    self.modelName = @"Arrow";
    self.textureName = @"crate.jpg";
    
    return self;
}

-(MBQObjectUpdateOut)update:(MBQObjectUpdateIn*)data
{
    MBQObjectUpdateOut outData = [super update:data];
    
    //destroy if offscreen
    if(!data->visibleOnScreen)
    {
        NSLog(@"Arrow offscreen, killing self.");
        self.enabled = false;
    }
    
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
    
    /* Only destroy the other object if it is NOT another arrow. */
    if (![otherObject isKindOfClass:[ArrowObject class]])
    {
        [self destroy];
    }
}

@end
