//
//  PlayerObject.m
//  minibattlequest
//
//  Created by Chris on 2017-01-31.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlayerObject.h"

@interface PlayerObject()
{
    
    
}
@end

@implementation PlayerObject
{
    MBQPoint2D target;
}

//we should override these (are they virtual by default like Java or not like C++?)
-(id)init
{
    self = [super init];
    return self;
}

-(void)update
{
    //I'm implementing most or all of these but you don't have to
    switch(self.state)
    {
        case STATE_SPAWNING:
            break;
        case STATE_DORMANT:
            break;
        case STATE_IDLING:
            break;
        case STATE_MOVING:
            break;
        case STATE_FIRING:
            break;
        case STATE_DYING:
            break;
        case STATE_DEAD:
            self.enabled = false;
            break;
        default:
            //do nothing
            break;
    }
}

-(void)display
{
    NSString *output = [NSString stringWithFormat:(@"Player at: (%.2f,%.2f)"), self.position.x, self.position.y];
    
    NSLog(output);
}

-(void)moveToTarget:(MBQPoint2D)newTarget
{
    self.state = STATE_MOVING;
    self->target = newTarget;
}

@end
