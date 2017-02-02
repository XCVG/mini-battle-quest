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

@interface GameObject : NSObject

@property GameObjectState state;
@property MBQPoint2D position;
@property BOOL enabled;
@property id box2dObject;
-(void)update;
-(void)display;

@end



#endif /* GameObject_h */
