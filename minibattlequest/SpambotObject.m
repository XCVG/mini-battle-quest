//
//  SpambotObject.m
//  minibattlequest
//
//  Created by Chris on 2017-02-08.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpambotObject.h"
#import "MeeseeksObject.h"

#define SPAWN_DELAY 5.0f

@interface SpambotObject()
{
    
    
}
@end

@implementation SpambotObject
{
    float _elapsed;
}

-(id)init
{
    self = [super init];
    return self;
}

-(MBQObjectUpdateOut)update:(MBQObjectUpdateIn*)data
{
    MBQObjectUpdateOut outData;
    
    if(self.state == STATE_SPAWNING)
    {
        _elapsed = 0.0f;
        self.state = STATE_IDLING;
    }
    else if(self.state == STATE_IDLING)
    {
        _elapsed += data->timeSinceLast;
        if(_elapsed >= SPAWN_DELAY)
        {
            self.state = STATE_FIRING;
            _elapsed = 0.0f;
        }
        
    }
    else if(self.state == STATE_FIRING)
    {
        id newGameObject = [[MeeseeksObject alloc] init];
        [data->newObjectArray addObject:newGameObject];
        self.state = STATE_IDLING;
    }
    else
    {
        self.enabled = false;
    }
    
    return outData;
}

//may need to rethink this; pass information back to scene to render
-(MBQObjectDisplayOut)display:(MBQObjectDisplayIn*)data
{
    MBQObjectDisplayOut outData;
    
    return outData;
}

@end
