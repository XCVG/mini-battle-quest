//
//  PlayerObject.m
//  minibattlequest
//
//  Created by Chris on 2017-01-31.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlayerObject.h"
#import "ArrowObject.h"

#define TARGET_THRESHOLD 32.0f
#define DEFAULT_MOVE_SPEED 100.0f
#define PLAYER_DEFAULT_HEALTH 200.0f

@interface PlayerObject()
{
    
    
}
@end

@implementation PlayerObject
{
    float _moveSpeed;
    
    MBQPoint2D _target; //the place we want to go
    
    id _currentTarget; //the enemy we want to hit
    
    float _elapsed; //elapsed; temporary for testing
}

//we should override these (are they virtual by default like Java or not like C++?)
-(id)init
{
    self = [super init];
    
    self.visible = true;
    self.solid = true;
    self.movable = true;
    self.health = PLAYER_DEFAULT_HEALTH;
    _moveSpeed = DEFAULT_MOVE_SPEED;
    
    
    return self;
}

-(MBQObjectUpdateOut)update:(MBQObjectUpdateIn*)data
{
    MBQObjectUpdateOut outData = [super update:data];
    
    _elapsed += data->timeSinceLast;
    
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
            [self searchForTargets];
            [self attackTarget];
            
            //TODO health check (may need to be in multiple parts)
            
            break;
        case STATE_MOVING:
            //TODO: we should probably check this in all states, not just MOVING
            {
                BOOL moved = [self checkMove];
                
                if(!moved)
                {
                    MBQVect2D newVelocity = {0.0f,0.0f};
                    self.velocity = newVelocity;
                    self.state = STATE_IDLING;
                }
                
                [self searchForTargets];
                [self attackTarget];
            }
            break;
        case STATE_FIRING:
            {
                //[self checkMove];
                //attacking
                
                //for testing: fire an arrow straight up and switch back to idle
                MBQVect2D vector = {0.0f, 100.0f};
                [self fireArrow:vector intoList:data->newObjectArray];
                
                self.state = STATE_IDLING;
            }
            break;
        case STATE_PAINING:
            //[self checkMove];
            //yes I know it's an awkward name
            
            //TODO any pain animation
            
            break;
        case STATE_DYING:
            //TODO death animation
            //TODO signal viewcontroller that player has died somehow
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

//check health
-(void)checkHealth
{
    if(self.health <= 0)
    {
        //set dying state and maybe other stuff
        self.state = STATE_DYING;
    }
}

//TODO: search for targets
-(void)searchForTargets
{
    
}

//TODO: attack a target
-(void)attackTarget
{
    //for testing: fire an arrow every few seconds
    if(_elapsed > 2.0f)
    {
        self.state = STATE_FIRING;
        
        _elapsed = 0.0f;
    }
}

//TODO: fire an arrow down the target bearing
-(void)fireArrow:(MBQVect2D)vector intoList:(NSMutableArray*)list
{
    GameObject *arrow = [[ArrowObject alloc] init];
    
    MBQPoint2D pos = self.position;
    pos.y += 64.0f;
    arrow.position = pos;

    //TODO: deal with speed/magnitude maybe?
    arrow.velocity = vector;
    
    [list addObject:arrow];
    
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

-(BOOL)checkMove
{
    //"move" to target
        BOOL moved = NO;
        
        //reworked to use velocity
        if(fabsf(_target.x - self.position.x) > TARGET_THRESHOLD && _target.x > self.position.x)
        {
            MBQVect2D newVelocity = {_moveSpeed,self.velocity.y};
            self.velocity = newVelocity;
            
            moved = YES;
        }
        else if(fabsf(_target.x - self.position.x) > TARGET_THRESHOLD && _target.x < self.position.x)
        {
            MBQVect2D newVelocity = {-_moveSpeed,self.velocity.y};
            self.velocity = newVelocity;
            
            moved = YES;
        }
        else
        {
            MBQVect2D newVelocity = {0.0f,self.velocity.y};
            self.velocity = newVelocity;
        }
        
        if(fabsf(_target.y - self.position.y) > TARGET_THRESHOLD && _target.y > self.position.y)
        {
            MBQVect2D newVelocity = {self.velocity.x,_moveSpeed};
            self.velocity = newVelocity;
            
            moved = YES;
        }
        else if(fabsf(_target.y - self.position.y) > TARGET_THRESHOLD && _target.y < self.position.y)
        {
            MBQVect2D newVelocity = {self.velocity.x,-_moveSpeed};
            self.velocity = newVelocity;
            
            moved = YES;
        }
        else
        {
            MBQVect2D newVelocity = {self.velocity.x,0.0f};
            self.velocity = newVelocity;
        }
        
        if(!moved)
        {
            MBQVect2D newVelocity = {0.0f,0.0f};
            self.velocity = newVelocity;
        }
        
        return moved;
}

@end
