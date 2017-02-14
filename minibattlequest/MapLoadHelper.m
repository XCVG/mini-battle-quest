//
//  MapLoadHelper.m
//  minibattlequest
//
//  Created by Chris on 2017-02-13.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapLoadHelper.h"

@interface MapLoadHelper()
{
    
}

@end

@implementation MapLoadHelper
{
    
}

+(NSMutableArray*)loadObjectsFromMap:(NSString*)map
{
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    //NSString *path = [mainBundle pathForResource:map ofType:@"json" inDirectory:@"Assets/Maps"];
    NSString *path = [mainBundle pathForResource:map ofType:@"json"];
    
    NSLog(path);
    
    //NSString *data = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    
    //NSError *error = nil;
    
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    return objects;
}

//TODO decoding JSON into GameObjects

@end
