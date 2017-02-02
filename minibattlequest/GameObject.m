//
//  GameObject.m
//  minibattlequest
//
//  Created by Chris on 2017-01-31.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameObject.h"

@interface GameObject()
{
    

}


@end

@implementation GameObject

//we may need parameters, I don't know
//for that matter, I don't really know how objC constructors work either
//we may need to do some kind of openGL init here
//it's looking increasingly like we'll need to pass data back and deal with it in the viewcontroller
-(id)init
{
    self = [super init];
    
    _state = STATE_SPAWNING;
    _position.x = 0.0f;
    _position.y = 0.0f;
    _enabled = true;
    
    return self;
}

-(void)update
{
    
}

//may need to rethink this; pass information back to scene to render
-(void)display
{
    
}

@end
