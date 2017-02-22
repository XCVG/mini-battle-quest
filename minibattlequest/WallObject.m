//
//  WallObject.m
//  minibattlequest
//
//  Created by Chris on 2017-02-07.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WallObject.h"

@interface WallObject()
{
    
    
}
@end

@implementation WallObject

-(id)init
{
    self = [super init];
    self.visible = true;
    self.solid = true;
    self.movable = false;
    return self;
}

-(MBQObjectUpdateOut)update:(MBQObjectUpdateIn*)data
{
    MBQObjectUpdateOut outData = [super update:data];
    
    return outData;
}

//may need to rethink this; pass information back to scene to render
-(MBQObjectDisplayOut)display:(MBQObjectDisplayIn*)data
{
    MBQObjectDisplayOut outData;
    
    return outData;
}

@end
