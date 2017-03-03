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
        
        [objects addObject:go];
    }
    
    return mapModel;
}

@end
