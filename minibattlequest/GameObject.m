//
//  GameObject.m
//  minibattlequest
//
//  Created by Chris on 2017-01-31.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameObject.h"

@interface GameObject()
{
    

}


@end

@implementation GameObject

//TODO: add parameters (also to subclasses)
-(id)init
{
    self = [super init];
    
    _state = STATE_SPAWNING;
    _position.x = 0.0f;
    _position.y = 0.0f;
    _zPosition = 0.0f;
    _velocity.x = 0.0f;
    _velocity.y = 0.0f;
    _scale = GLKVector3Make(1.0f, 1.0f, 1.0f);
    _health = GO_DEFAULT_HEALTH;
    _enabled = true;
    _visible = true;
    _solid = false;
    
    return self;
}

-(MBQObjectUpdateOut)update:(MBQObjectUpdateIn*)data
{
    MBQObjectUpdateOut outData;
    
    if(self.movable)
    {
        MBQPoint2D newPosition;
        newPosition.x = self.position.x + (data->timeSinceLast * self.velocity.x);
        newPosition.y = self.position.y + (data->timeSinceLast * self.velocity.y);
        self.position = newPosition;
    }
    
    return outData;
}

//may need to rethink this; pass information back to scene to render
-(MBQObjectDisplayOut)display:(MBQObjectDisplayIn*)data
{
    MBQObjectDisplayOut outData;
    //outData.modelHandle = self.modelHandle;
    outData.textureHandle = self.textureHandle;
    outData.dPosition = GLKVector3Make(self.position.x, self.position.y, self.zPosition);
    outData.dRotation = GLKVector3Make(0.0f, 0.0f, GLKMathDegreesToRadians(self.rotation)); //might need to negative this
    outData.dScale = GLKVector3Make(1.0f, 1.0f, 1.0f);
    outData.numVertices = _numVertices;
    
    
    return outData;
}

-(void)onCollision:(GameObject*)otherObject
{
    NSLog(@"Something Hit an Object!");
}

-(void)destroy
{
    self.enabled = NO;
}

@end
