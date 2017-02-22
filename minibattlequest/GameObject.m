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
    _health = GO_DEFAULT_HEALTH;
    _enabled = true;
    
    return self;
}

-(MBQObjectUpdateOut)update:(MBQObjectUpdateIn*)data
{
    MBQObjectUpdateOut outData;
    
    return outData;
}

//may need to rethink this; pass information back to scene to render
-(MBQObjectDisplayOut)display:(MBQObjectDisplayIn*)data
{
    MBQObjectDisplayOut outData;
    
    return outData;
}

@end
