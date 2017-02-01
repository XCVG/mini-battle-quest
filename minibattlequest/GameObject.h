//
//  GameObject.h
//  minibattlequest
//
//  Created by Chris on 2017-01-31.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#ifndef GameObject_h
#define GameObject_h

@interface GameObject : NSObject

@end

typedef NS_ENUM(NSInteger, GameObjectState) {
SPAWNING, DORMANT, IDLING, MOVING, FIRING, DYING, DEAD //from PARROTGAME, we can change this
};

typedef struct point2D{
    float x;
    float y;
} point2D;

#endif /* GameObject_h */
