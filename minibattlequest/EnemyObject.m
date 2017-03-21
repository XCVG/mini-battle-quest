//
//  EnemyObject.m
//  minibattlequest
//
//  Created by Chris on 2017-01-31.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyObject.h"
#import "ArrowObject.h"

#define ENEMY_DEFAULT_SCALE 25.0f
#define ENEMY_DEFAULT_HEALTH 100.0f

#define TARGET_THRESHOLD 32.0f
#define DEFAULT_MOVE_SPEED 160.0f

#define ENEMY_FIRE_CHANCE 0.1f
#define ENEMY_MOVE_CHANCE 0.1f
#define ENEMY_ABORTMOVE_CHANCE 0.05f
#define ENEMY_DEFAULT_ARROWVELOCITY 500.0f

@interface EnemyObject()
{
    
    
}
@end

@implementation EnemyObject
{
    float _moveSpeed;
    float _arrowVelocity;
    float _arrowDamageOverride;
}

//we should override these (are they virtual by default like Java or not like C++?)
-(id)init
{
    self = [super init];
    self.solid = true;
    self.visible = true;
    self.movable = true;
    self.scale = GLKVector3Make(ENEMY_DEFAULT_SCALE, ENEMY_DEFAULT_SCALE, ENEMY_DEFAULT_SCALE);
    self.size = 64.0f;
    self.modelRotation = GLKVector3Make(0.8f, 0.0f, 0.0f);
    _moveSpeed = DEFAULT_MOVE_SPEED;
    _arrowVelocity = ENEMY_DEFAULT_ARROWVELOCITY;
    _arrowDamageOverride = -1;
    return self;
}

-(MBQObjectUpdateOut)update:(MBQObjectUpdateIn*)data
{
    MBQObjectUpdateOut outData = [super update:data];
    
    switch(self.state)
    {
        case STATE_SPAWNING:
            //do any spawning animation etc here
            
            //go straight to idle
            self.state = STATE_IDLING;
            break;
        case STATE_DORMANT:
            //go active when you go on screen
            if(data->visibleOnScreen)
                self.state = STATE_IDLING;
            break;
        case STATE_IDLING:
            {
                //decide to move or fire
                [self decideAction];
            }
            break;
        case STATE_MOVING:
            {
                //move
                //follow the player, don't go offscreen
                if(self.position.x < ((GameObject*)data->player).position.x)
                {
                    self.velocity = GLKVector2Make(_moveSpeed, 0);
                }
                else if(self.position.x > ((GameObject*)data->player).position.x)
                {
                    self.velocity = GLKVector2Make(-_moveSpeed, 0);
                }
                
                //TODO: random chance to switch direction or continue and not track
                
                //TODO: abort movement on 
                
                //stop movement on reaching threshold or going too far
                if(fabsf(((GameObject*)data->player).position.x - self.position.x) < TARGET_THRESHOLD
                   || (self.velocity.x > 0 && self.position.x > ((GameObject*)data->player).position.x)
                   || (self.velocity.x < 0 && self.position.x < ((GameObject*)data->player).position.x))
                {
                    self.velocity = GLKVector2Make(0, 0);
                    self.state = STATE_IDLING;
                }
                
                //occasionally abort movement
                float diceRoll = (double)arc4random() / UINT32_MAX;
                if(diceRoll <= ENEMY_ABORTMOVE_CHANCE)
                {
                    self.velocity = GLKVector2Make(0, 0);
                    self.state = STATE_IDLING;
                }
                
            }
            break;
        case STATE_FIRING:
            {
                //fire an arrow
                GLKVector2 vector = GLKVector2Make(0.0f, -_arrowVelocity);
                ArrowObject *arrow = [self fireArrow:vector intoList:data->newObjectArray];
                if(_arrowDamageOverride>0)
                    arrow.damage = _arrowDamageOverride;
                self.state = STATE_IDLING;
            }
            break;
        case STATE_PAINING:           
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

//may need to rethink this; pass information back to scene to render
-(MBQObjectDisplayOut)display:(MBQObjectDisplayIn*)data
{
    MBQObjectDisplayOut outData;
    
    return outData;
}

-(void)onCollision:(GameObject*)otherObject
{
    NSLog(@"Something Hit an Enemy!");
    if ([otherObject isKindOfClass:[ArrowObject class]])
    {
        //lose health points
        ArrowObject * myArrow = (ArrowObject*)otherObject;
        [self takeDamage:myArrow.damage];
    }
}

-(void)takeDamage:(float)damage
{
    self.health -= damage;
    NSLog(@"Ouch! Health: %f",self.health);
    
    if (self.health <= 0)
    {
        NSLog(@"I dun gone died!");
        [self destroy];
    }
}

-(void)decideAction
{
    float diceRoll = (double)arc4random() / UINT32_MAX;
    if(diceRoll <= ENEMY_MOVE_CHANCE)
    {
        //move
        //NSLog(@"Enemy Move!");
        self.state = STATE_MOVING;
        return;
    }
    diceRoll = (double)arc4random() / UINT32_MAX;
    if(diceRoll <= ENEMY_FIRE_CHANCE)
    {
        //fire
        //NSLog(@"Enemy Fire!");
        self.state = STATE_FIRING;
        return;
    }
    
}

-(ArrowObject*)fireArrow:(GLKVector2)vector intoList:(NSMutableArray*)list
{
    NSLog(@"Arrow Fired by enemy!");
    
    GameObject *arrow = [[ArrowObject alloc] init];
    
    arrow.position = GLKVector3Make(self.position.x, self.position.y-50.0f, self.position.z);
    arrow.rotation = GLKVector3Make(arrow.rotation.x, arrow.rotation.y, arrow.rotation.z+M_PI);
    
    //TODO: deal with speed/magnitude maybe?
    arrow.velocity = vector;
    
    [list addObject:arrow];
    
    return arrow;
    
}

@end
