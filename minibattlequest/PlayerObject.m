//
//  PlayerObject.m
//  minibattlequest
//
//  Created by Chris on 2017-01-31.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlayerObject.h"

#define TARGET_THRESHOLD 32.0f
#define DEFAULT_MOVE_SPEED 8.0f

@interface PlayerObject()
{
    
    
}
@end

@implementation PlayerObject
{
    float _moveSpeed;
    
    MBQPoint2D _target;
}

//we should override these (are they virtual by default like Java or not like C++?)
-(id)init
{
    self = [super init];
    
    _moveSpeed = DEFAULT_MOVE_SPEED;
    
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
            //TODO "move" to target
            {
                BOOL moved = NO;
                
                if(_target.x - self.position.x > TARGET_THRESHOLD)
                {
                    MBQPoint2D p = self.position;
                    
                    p.x += _moveSpeed;
                    
                    self.position = p;
                    moved = YES;
                }
                else if(_target.x - self.position.x < TARGET_THRESHOLD)
                {
                    MBQPoint2D p = self.position;
                    
                    p.x -= _moveSpeed;
                    
                    self.position = p;
                    moved = YES;
                }
                
                if(_target.y - self.position.y > TARGET_THRESHOLD)
                {
                    MBQPoint2D p = self.position;
                    
                    p.y += _moveSpeed;
                    
                    self.position = p;
                    moved = YES;
                }
                else if(_target.y - self.position.y < TARGET_THRESHOLD)
                {
                    MBQPoint2D p = self.position;
                    
                    p.y -= _moveSpeed;
                    
                    self.position = p;
                    moved = YES;
                }
                
                if(!moved)
                    self.state = STATE_IDLING;
            }
            
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
    NSString *output = [NSString stringWithFormat:(@"Target at: (%.2f,%.2f)"), newTarget.x, newTarget.y];
    
    NSLog(output);
    
    self.state = STATE_MOVING;
    self->_target = newTarget;
}

@end
