//
//  MeeseeksObject.m
//  minibattlequest
//
//  Created by Chris on 2017-02-08.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MeeseeksObject.h"
#define MEESEEKS_MAX_TIME 10.0f

@interface MeeseeksObject()
{
    
    
}
@end

@implementation MeeseeksObject
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
        //start countdown
        NSLog(@"I'm Mr. Meeseeks! Look at me!");
        _elapsed = 0.0f;
        self.state = STATE_IDLING;
    }
    else if(self.state == STATE_IDLING)
    {
        //count down
        _elapsed += data->timeSinceLast;
        
        if(_elapsed >= MEESEEKS_MAX_TIME)
        {
            self.state = STATE_DYING;
        }
        
    }
    else
    {
        //die
        NSLog(@"Mr. Meeseeks: *pop*");
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
