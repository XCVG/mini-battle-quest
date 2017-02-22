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
    
    self.visible = true;
    self.solid = true;
    self.movable = true;
    _moveSpeed = DEFAULT_MOVE_SPEED;
    
    
    return self;
}

-(MBQObjectUpdateOut)update:(MBQObjectUpdateIn*)data
{
    MBQObjectUpdateOut outData = [super update:data];
    
    //I'm implementing most or all of these but you don't have to
    switch(self.state)
    {
        case STATE_SPAWNING:
            //do any spawning animation etc here
            
            //go straight to idle
            self.state = STATE_IDLING;
            break;
        case STATE_DORMANT:
            
            //player cannot be dormant, go straight to idle
            self.state = STATE_IDLING;
            break;
        case STATE_IDLING:
            
            //TODO search for and attack enemies
            
            //TODO health check
            
            break;
        case STATE_MOVING:
            //TODO "move" to target
            {
                BOOL moved = NO;
                
                //TODO: rework to use velocity
                if(fabsf(_target.x - self.position.x) > TARGET_THRESHOLD && _target.x > self.position.x)
                {
                    MBQPoint2D p = self.position;
                    
                    p.x += _moveSpeed;
                    
                    self.position = p;
                    moved = YES;
                }
                else if(fabsf(_target.x - self.position.x) > TARGET_THRESHOLD && _target.x < self.position.x)
                {
                    MBQPoint2D p = self.position;
                    
                    p.x -= _moveSpeed;
                    
                    self.position = p;
                    moved = YES;
                }
                
                if(fabsf(_target.y - self.position.y) > TARGET_THRESHOLD && _target.y > self.position.y)
                {
                    MBQPoint2D p = self.position;
                    
                    p.y += _moveSpeed;
                    
                    self.position = p;
                    moved = YES;
                }
                else if(fabsf(_target.y - self.position.y) > TARGET_THRESHOLD && _target.y < self.position.y)
                {
                    MBQPoint2D p = self.position;
                    
                    p.y -= _moveSpeed;
                    
                    self.position = p;
                    moved = YES;
                }
                
                //TODO: search for/attack enemies?
                
                if(!moved)
                    self.state = STATE_IDLING;
            }
            
            break;
        case STATE_FIRING:
            //attacking 
            
            break;
        case STATE_PAINING:
            //yes I know it's an awkward name
            
            //TODO any pain animation
            
            break;
        case STATE_DYING:
            //TODO death animation
            
            break;
        case STATE_DEAD:
            self.enabled = false;
            break;
        default:
            //do nothing
            break;
    }
    
    
    return outData;
}

-(MBQObjectDisplayOut)display:(MBQObjectDisplayIn*)data
{
    MBQObjectDisplayOut dataOut;
    
    NSString *output = [NSString stringWithFormat:(@"Player at: (%.2f,%.2f)"), self.position.x, self.position.y];
    
    NSLog(output);
    
    return dataOut;
}

-(void)moveToTarget:(MBQPoint2D)newTarget
{
    //state checks
    if(self.state == STATE_SPAWNING || self.state == STATE_DORMANT || self.state == STATE_DYING || self.state == STATE_DEAD)
    {
        return;
    }
    
    NSString *output = [NSString stringWithFormat:(@"Target at: (%.2f,%.2f)"), newTarget.x, newTarget.y];
    
    NSLog(output);
    
    self.state = STATE_MOVING;
    self->_target = newTarget;
}

@end
