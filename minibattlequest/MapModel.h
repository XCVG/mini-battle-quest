//
//  MapModel.h
//  minibattlequest
//
//  Created by Chris on 2017-02-14.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#ifndef MapModel_h
#define MapModel_h

@interface MapModel : NSObject

@property NSString* name;
@property NSString* music;
@property NSString* background;
@property float length;
@property float backgroundLength;
@property NSMutableArray* objects;

@end

#endif /* MapModel_h */
