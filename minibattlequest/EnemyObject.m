//
//  EnemyObject.m
//  minibattlequest
//
//  Created by Chris on 2017-01-31.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyObject.h"

@interface EnemyObject()
{
    
    
}
@end

@implementation EnemyObject

//we should override these (are they virtual by default like Java or not like C++?)
-(id)init
{
    self = [super init];
    self.solid = true;
    self.visible = true;
    self.movable = true;
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
