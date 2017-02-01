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
@property GameObjectState state;
@property id box2dObject;
-(void)update;
-(void)display;

@end

@implementation GameObject

//we may need parameters, I don't know
//for that matter, I don't really know how objC constructors work either
-(id)init
{
    self = [super init];
    return self;
}

-(void)update
{
    
}

-(void)display
{
    
}

@end
