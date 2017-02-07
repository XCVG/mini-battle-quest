//
//  GOTypes.h
//  minibattlequest
//
//  Created by Chris on 2017-02-02.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#ifndef GOTypes_h
#define GOTypes_h

//may move these; I don't know a lot about header files
typedef NS_ENUM(NSInteger, GameObjectState) {
    STATE_SPAWNING, STATE_DORMANT, STATE_IDLING, STATE_MOVING, STATE_FIRING, STATE_PAINING, STATE_DYING, STATE_DEAD //from PARROTGAME, we can change this
};

typedef struct MBQPoint2D{
    float x;
    float y;
} MBQPoint2D;


//for data passed into a GameObject during update()
typedef struct MBQObjectUpdateIn{
    
} MBQObjectUpdateIn;

//for data passed out of a GameObject during update()
//(may not be needed)
typedef struct MBQObjectUpdateOut{
    
} MBQObjectUpdateOut;

//for data passed into a GameObject during display()
typedef struct MBQObjectDisplayIn{
    
} MBQObjectDisplayIn;

//for data passed out of a GameObject during display()
typedef struct MBQObjectDisplayOut{
    
} MBQObjectDisplayOut;

//for data passed into a GameObject after collision (not including other gameobject)
typedef struct MBQObjectCollideContext {
    
} MBQObjectCollideContext;

#endif /* GOTypes_h */
