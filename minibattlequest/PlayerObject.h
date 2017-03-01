//
//  PlayerObject.h
//  minibattlequest
//
//  Created by Chris on 2017-01-31.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#ifndef PlayerObject_h
#define PlayerObject_h

#import "GameObject.h"

@interface PlayerObject : GameObject
@property MBQWeapon weapon;

-(void)moveToTarget:(MBQPoint2D)target;

@end

#endif /* PlayerObject_h */
