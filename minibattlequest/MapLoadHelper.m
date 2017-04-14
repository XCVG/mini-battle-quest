//
//  MapLoadHelper.m
//  minibattlequest
//
//  Created by Chris on 2017-02-13.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapLoadHelper.h"
#import "GameObject.h"

@interface MapLoadHelper()
{
    
}

@end

@implementation MapLoadHelper
{
    
}

+(MapModel*)loadObjectsFromMap:(NSString*)map
{
    MapModel *mapModel = [[MapModel alloc] init];
    
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    mapModel.objects = objects; //this is fine
    
    NSBundle *mainBundle = [NSBundle mainBundle];

    NSString *path = [mainBundle pathForResource:map ofType:@"json"];
    
    //NSLog(path);

    NSData *data = [[NSData alloc] initWithContentsOfFile:path];

    
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    //get non-object propertiess
    mapModel.name = [jsonObject valueForKey:@"name"];
    mapModel.music = [jsonObject valueForKey:@"music"];
    mapModel.background = [jsonObject valueForKey:@"background"];
    mapModel.length = [(NSNumber*)[jsonObject valueForKey:@"length"] floatValue];
    mapModel.backgroundLength = [(NSNumber*)[jsonObject valueForKey:@"background_length"] floatValue];
    
    NSArray *jsonArrayOfGameObjects = [jsonObject valueForKey:@"objects"];
    
    //iterate through object and generate gameobjects
    for(NSDictionary* object in jsonArrayOfGameObjects)
    {
        //type, x, y, don't use state because it's unused
        GameObject* go = (GameObject*)[[NSClassFromString([object valueForKey:@"type"]) alloc] init];
        GLKVector3 pos;
        pos.x = [(NSNumber*)[object valueForKey:@"x"] floatValue];
        pos.y = [(NSNumber*)[object valueForKey:@"y"] floatValue];
        go.position =  pos;
        
        //additional, dependent modifiers
        if([object objectForKey:@"z"])
            go.position = GLKVector3Make(pos.x, pos.y, [(NSNumber*)[object valueForKey:@"z"] floatValue]);
        
        if([object objectForKey:@"scaleX"])
            go.scale = GLKVector3Make([(NSNumber*)[object valueForKey:@"scaleX"] floatValue], go.scale.y, go.scale.z);
        
        if([object objectForKey:@"scaleY"])
            go.scale = GLKVector3Make(go.scale.x, [(NSNumber*)[object valueForKey:@"scaleY"] floatValue], go.scale.z);
        
        if([object objectForKey:@"scaleZ"])
            go.scale = GLKVector3Make(go.scale.x, go.scale.y, [(NSNumber*)[object valueForKey:@"scaleZ"] floatValue]);
        
        if([object objectForKey:@"rotX"])
            go.rotation = GLKVector3Make([(NSNumber*)[object valueForKey:@"rotX"] floatValue], go.rotation.y, go.rotation.z);
        
        if([object objectForKey:@"rotY"])
            go.rotation = GLKVector3Make(go.rotation.x, [(NSNumber*)[object valueForKey:@"rotY"] floatValue], go.rotation.z);
        
        if([object objectForKey:@"rotZ"])
            go.rotation = GLKVector3Make(go.rotation.x, go.rotation.y, [(NSNumber*)[object valueForKey:@"rotZ"] floatValue]);
        
        if([object objectForKey:@"texture"])
            go.textureName = [object valueForKey:@"texture"];
        
        if([object objectForKey:@"isBoss"])
            go.isBoss = YES;
        
        if([object objectForKey:@"model"])
            go.modelName = [object valueForKey:@"model"];
        
        if([object objectForKey:@"health"])
        {
            float newHealth = [(NSNumber*)[object valueForKey:@"health"] floatValue];
            go.maxHealth = newHealth;
            go.health = newHealth;
        }
        
        if([object objectForKey:@"size"])
            go.size = [(NSNumber*)[object valueForKey:@"size"] floatValue];
        
        [objects addObject:go];
    }
    
    return mapModel;
}

@end
