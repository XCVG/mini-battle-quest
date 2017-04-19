//
//  PlayerObject.m
//  minibattlequest
//
//  Created by Chris on 2017-01-31.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "PlayerObject.h"
#import "ArrowObject.h"
#import "WallObject.h"

#define TARGET_THRESHOLD 32.0f
#define DEFAULT_MOVE_SPEED 250.0f
#define PLAYER_DEFAULT_HEALTH 500.0f
#define PLAYER_DEFAULT_SCALE 25.0f
#define PLAYER_BOUNCE_FACTOR 0.5f
#define PLAYER_BOUNCE_DELAY 1.0f
#define PLAYER_ARROW_SPEED 1000.0f
#define PLAYER_FIRE_RATE 1.5f

@interface PlayerObject()
{
    
    
}

@property (strong, nonatomic) AVAudioPlayer *playerAudio;

@end

@implementation PlayerObject
{
    float _moveSpeed;
    
    GLKVector2 _moveTarget; //the place we want to go
    BOOL _hasMoveTarget;
    
    id _currentTarget; //the enemy we want to hit
    
    float _elapsed; //elapsed; temporary for testing
    
    NSURL *sfxShootArrowPath;
    NSURL *sfxHitPath;
    NSURL *sfxBlockPath;
}

//we should override these (are they virtual by default like Java or not like C++?)
-(id)init
{
    self = [super init];
    
    self.scale = GLKVector3Make(PLAYER_DEFAULT_SCALE, PLAYER_DEFAULT_SCALE, PLAYER_DEFAULT_SCALE);
    
    self.visible = true;
    self.solid = true;
    self.movable = true;
    self.maxHealth = PLAYER_DEFAULT_HEALTH;
    self.health = PLAYER_DEFAULT_HEALTH;
    self.modelRotation = GLKVector3Make(0.8f, 3.14f, 0.0f);
    self.size = 69.0f;
    _moveSpeed = DEFAULT_MOVE_SPEED;
    _isUsingWeapon = NO;
    self.modelName = @"player";
    self.textureName = @"Player_Texture.png";
    
    sfxShootArrowPath = [[NSBundle mainBundle] URLForResource:@"ShootArrow" withExtension:@"mp3"];
    sfxHitPath = [[NSBundle mainBundle] URLForResource:@"Hit" withExtension:@"mp3"];
    sfxBlockPath = [[NSBundle mainBundle] URLForResource:@"Block" withExtension:@"mp3"];
     
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error: nil];
    
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
            //[self checkMove];
            if (_isUsingWeapon)
            {
                [self searchForTargets];
                [self attackTarget];
            }
            
            //TODO health check (may need to be in multiple parts)
            
            break;
        case STATE_MOVING:
            //TODO: we should probably check this in all states, not just MOVING
            {
                [self returnToIdle];
                
                if (_isUsingWeapon)
                {
                    [self searchForTargets];
                    [self attackTarget];
                }
            }
            break;
        case STATE_FIRING:
            {
                //[self checkMove];
                //attacking
                
                //for testing: fire an arrow straight up and switch back to idle
                GLKVector2 vector = GLKVector2Make(0.0f, PLAYER_ARROW_SPEED);
                [self fireArrow:vector intoList:data->newObjectArray];
                
                [self returnToIdle];
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
        case STATE_BOUNCING:
            {
                if(_elapsed >= PLAYER_BOUNCE_DELAY)
                {
                    self.velocity = GLKVector2Make(0, 0);
                    self.state = STATE_IDLING;
                    _elapsed = 0;
                }
            }
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
    
    //NSString *output = [NSString stringWithFormat:(@"Player at: (%.2f,%.2f)"), self.position.x, self.position.y];
    
    //NSLog(output);
    
    return dataOut;
}

-(void)onCollision:(GameObject*)otherObject
{
    NSLog(@"Player hit something!");
    
    //if the other thing is a wall, stop me!
    if ([otherObject isKindOfClass:[WallObject class]])
    {
        _hasMoveTarget = NO;
        self.state = STATE_BOUNCING;
        self.velocity = GLKVector2Make(-self.velocity.x*PLAYER_BOUNCE_FACTOR, -self.velocity.y*PLAYER_BOUNCE_FACTOR);
    }
    /* If the other thing is an arrow and I don't have my shield up, damage me! */
    else if ([otherObject isKindOfClass:[ArrowObject class]] && self.isUsingWeapon)
    {
        ArrowObject * myArrow = (ArrowObject*)otherObject;
        [self takeDamage:myArrow.damage];
        NSLog(@"Player Health: %f", self.health);
        [self.playerAudio stop];
        self.playerAudio = [[AVAudioPlayer alloc] initWithContentsOfURL:sfxHitPath error:nil];
        self.playerAudio.numberOfLoops = 0;
        [self.playerAudio play];
    }
    else if ([otherObject isKindOfClass:[ArrowObject class]] && !self.isUsingWeapon)
    {
        [self.playerAudio stop];
        self.playerAudio = [[AVAudioPlayer alloc] initWithContentsOfURL:sfxBlockPath error:nil];
        self.playerAudio.numberOfLoops = 0;
        [self.playerAudio play];
    }
    
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
    if(_elapsed > PLAYER_FIRE_RATE)
    {
        self.state = STATE_FIRING;
        
        _elapsed = 0.0f;
    }
}

//TODO: fire an arrow down the target bearing
-(void)fireArrow:(GLKVector2)vector intoList:(NSMutableArray*)list
{
    NSLog(@"Arrow Fired!");
    
    ArrowObject *arrow = [[ArrowObject alloc] init];
    
    arrow.position = GLKVector3Make(self.position.x, self.position.y+50.0f, self.position.z);

    //TODO: deal with speed/magnitude maybe?
    arrow.velocity = vector;
    
    [list addObject:arrow];
    
    [self.playerAudio stop];
    self.playerAudio = [[AVAudioPlayer alloc] initWithContentsOfURL:sfxShootArrowPath error:nil];
    self.playerAudio.numberOfLoops = 0;
    [self.playerAudio play];
    
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
    
    [self startMove:GLKVector2Make(newTarget.x, newTarget.y)];

}

//TODO: may move some of these functions into GameObject if we want them to be common

//determine direction and start moving
-(void)startMove:(GLKVector2)target
{
    _moveTarget = target;
    _hasMoveTarget = YES;
    
    GLKVector2 velocity = GLKVector2Normalize(GLKVector2Subtract(_moveTarget, GLKVector2Make(self.position.x, self.position.y)));
    velocity = GLKVector2MultiplyScalar(velocity, _moveSpeed);
    self.velocity = velocity;
    
    if(self.state == STATE_IDLING)
    {
        self.state = STATE_MOVING;
    }
}

//this checks and ends, but does not start, moving
-(BOOL)checkMove
{
    //"move" to target
    BOOL moved = YES;
    
    if(fabsf(_moveTarget.x - self.position.x) < TARGET_THRESHOLD && fabsf(_moveTarget.y - self.position.y) < TARGET_THRESHOLD)
    {
        //we're within the threshold, so stop moving and signal
        self.velocity = GLKVector2Make(0, 0);
        moved = NO;
        _hasMoveTarget = NO;
    }
    
    
    return moved;
}

//returns to MOVING if moving, else returns to IDLE
-(void)returnToIdle
{
    if([self checkMove])
    {
        self.state = STATE_MOVING;
    }
    else
    {
        self.state = STATE_IDLING;
    }
}

@end
