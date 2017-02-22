//
//  GameObject.h
//  minibattlequest
//
//  Created by Chris on 2017-01-31.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#ifndef GameObject_h
#define GameObject_h

#import "GOTypes.h"

#define GO_DEFAULT_HEALTH 100.0f

@interface GameObject : NSObject

@property GameObjectState state;
@property MBQPoint2D position;
@property float zPosition;
@property float size; //Need this for collisions detection
@property MBQVect2D velocity;
@property BOOL enabled; //if disabled, delete
@property BOOL visible; //draw if visible
@property BOOL solid; //collide if solid
@property BOOL movable; //move if movable
@property float health;

-(MBQObjectUpdateOut)update:(MBQObjectUpdateIn*)data;
-(MBQObjectDisplayOut)display:(MBQObjectDisplayIn*)data;
-(bool)checkCollisionBetweenObject:(GameObject *)one and:(GameObject *)two; //MICHAEL'S Collision function declaration

@end



#endif /* GameObject_h */
