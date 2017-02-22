//
//  MapLoadHelper.h
//  minibattlequest
//
//  Created by Chris on 2017-02-13.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#ifndef MapLoadHelper_h
#define MapLoadHelper_h
#import "MapModel.h"

@interface MapLoadHelper : NSObject

+(MapModel*)loadObjectsFromMap:(NSString*)map;

@end


#endif /* MapLoadHelper_h */
