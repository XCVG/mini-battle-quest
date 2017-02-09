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

//we could use an actual vector class, but this is (in theory) faster
//I had some functions somewhere but don't know where to put them
typedef struct MBQVect2D{
    float x;
    float y;
} MBQVect2D;

//for data passed into a GameObject during update()
typedef struct MBQObjectUpdateIn{
    float timeSinceLast;
    BOOL visibleOnScreen;
    __unsafe_unretained NSMutableArray *newObjectArray; //objects can put new objects here
    
} MBQObjectUpdateIn;

//for data passed out of a GameObject during update()
//(may not be needed)
typedef struct MBQObjectUpdateOut{
    //so originally I was going to pass back newly created objects here, but ARC doesn't like that
    //leaving me with a few options:
    //1. disable ARC and confuse the rest of the team
    //2. reimplement this with objects instead of structs (heavy!)
    //3. pass a pointer to a mutable array into ObjectUpdateIn instead
    //this may become a problem with rendering so we'll figure that out
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
