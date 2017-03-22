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


#define GO_DEFAULT_HEALTH 100.0f

@interface GameObject : NSObject

//struct that stores the vertex info
// maybe move vertex position in here as well and get rid of MBQPoint2D?
/*
struct VertexInfo
{
    GLuint vArray; //pointer to vertex array
    GLuint vBuffer; //pointer to vertex buffer
    int   length; //# of vertices

};
*/
typedef struct
{
    GLuint vArray; //pointer to vertex array
    GLuint vBuffer; //pointer to vertex buffer
    GLuint textureHandle;//the texture of the object
    int   length; //# of vertices

} VertexInfo;
@property NSString* textureName; //file name of the texture image
@property NSString* modelName; //file name of the obj model file

@property GameObjectState state;
@property GLKVector3 position;
@property GLKVector3 rotation;
@property GLKVector3 scale;
@property float size; //Need this for collisions detection
@property GLKVector2 velocity;
@property BOOL enabled; //if disabled, delete
@property BOOL visible; //draw if visible
@property BOOL solid; //collide if solid
@property BOOL movable; //move if movable
@property float health;

//used for model stuff. Now Accessed directly from here instead of using MBQobjectout bullshit
@property VertexInfo modelHandle;
@property GLuint numVertices; //redundant
//@property float modelxPos, modelyPos;
@property GLKVector3 modelRotation;

@property float maxHealth;


-(MBQObjectUpdateOut)update:(MBQObjectUpdateIn*)data;
-(MBQObjectDisplayOut)display:(MBQObjectDisplayIn*)data;

-(bool)checkCollisionBetweenObject:(GameObject *)one and:(GameObject *)two; //MICHAEL'S Collision function declaration
-(void)onCollision:(GameObject*)otherObject;
-(void)takeDamage:(float)damage;
-(void)destroy;

@end



#endif /* GameObject_h */
