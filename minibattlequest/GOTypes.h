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
    STATE_SPAWNING, STATE_DORMANT, STATE_IDLING, STATE_MOVING, STATE_FIRING, STATE_DYING, STATE_DEAD //from PARROTGAME, we can change this
};

typedef struct MBQPoint2D{
    float x;
    float y;
} MBQPoint2D;


#endif /* GOTypes_h */
