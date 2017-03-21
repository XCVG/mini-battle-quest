//
//  GameViewController.m
//  minibattlequest
//
//  Created by Chris Leclair on 2017-01-24.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#import "GameViewController.h"
#import <OpenGLES/ES2/glext.h>

#import "MapLoadHelper.h"
#import "GameObject.h"
#import "PlayerObject.h"
#import "EnemyObject.h"
#import "ArrowObject.h"
#import "MeeseeksObject.h"
#import "SpambotObject.h"
#include "ModelData.m"

#import <AudioToolbox/AudioToolbox.h>

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

//this was, in retrospect, a really, really bad idea
#define VIEWPORT_WIDTH 720.0f
#define VIEWPORT_HEIGHT 1280.0f

#define VIEWPORT_OVERSCAN 100.0f

#define SCROLL_UPPER_BOUND 800.0f
#define SCROLL_LOWER_BOUND 200.0f
#define SCROLL_SPEED 35.0f
#define SCROLL_FACTOR 2.0f

#define RENDER_MODEL_SCALE 1.0f

//TODO global and specific scale as well as default scale


// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};



@interface GameViewController () {
    GLuint _program;
    //TODO: completely redo the way shaders/programs are referenced and handled
    //also, these probably don't need to be in interface
    GLuint _bgProgram;
    GLuint _bgVertexArray;
    GLuint _bgVertexBuffer;
    GLuint _bgTexture;
    GLuint _bgTexCoordSlot;
    GLuint _bgTexUniform;
    float _bgLengthScale;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    float _rotation;
    
    VertexInfo playerVert, enemyVert, arrowVert;
    
    //GLuint  _sphereVertexArray, _cubeVertexArray;
   // GLuint  _sphereVertexBuffer, _cubeVertexBuffer;
    
    SystemSoundID soundEffect;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

@property (weak, nonatomic) IBOutlet UIButton *toggleWeaponButton;


-(void)handleViewportTap:(UITapGestureRecognizer *)tapGestureRecognizer;
- (void)setupGL;
- (void)tearDownGL;
- (bool)CheckCollision;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

@end

@implementation GameViewController {
    
    MapModel* _mapModel;
    
    //game variables
    NSMutableArray *_gameObjects;
    PlayerObject *_player;
    EnemyObject  *_enemy;
    NSMutableArray *_gameObjectsInView;
    NSMutableArray *_gameObjectsToAdd;
    
    float _scrollPos;
    BOOL _scrolling;
    
    BOOL _running;
    
    
    //viewport pseudoconstants
    float _screenToViewportX;
    float _screenToViewportY;
    float _screenActualHeight;
    
    SystemSoundID HitSfx;
    SystemSoundID ShootArrowSfx;
    
    /* Attack button images. */
    UIImage *_attackButtonWeaponImage;
    UIImage *_attackButtonShieldImage;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self calculateRatios];
    
    [self setupGame];
    
    [self setupGL];
    
    //audio paths
    NSString *hitSoundPath = [[NSBundle mainBundle] pathForResource:@"Hit" ofType:@"mp3"];
    NSURL *hitSoundPathURL = [NSURL fileURLWithPath : hitSoundPath];
    
    NSString *shootArrowSoundPath = [[NSBundle mainBundle] pathForResource:@"ShootArrow" ofType:@"mp3"];
    NSURL *shootArrowSoundPathURL = [NSURL fileURLWithPath : shootArrowSoundPath];
    
    //create audio
    AudioServicesCreateSystemSoundID((__bridge CFURLRef) hitSoundPathURL, &HitSfx);
    AudioServicesCreateSystemSoundID((__bridge CFURLRef) shootArrowSoundPathURL, &ShootArrowSfx);
    
    /* Get attack button images. */
    _attackButtonWeaponImage = [UIImage imageNamed:@"mbq_img_button_action_bow.png"];
    _attackButtonShieldImage = [UIImage imageNamed:@"mbq_img_button_action_shield.png"];
}

- (void)dealloc
{
    [self tearDownGame];
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    //may need to save state here
    
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGame];
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)setupGame
{
    NSLog(@"Starting game...");
    
    NSLog(@"creating 'objects to add' array");
    _gameObjectsToAdd = [[NSMutableArray alloc] init];
    
    NSLog(@"creating gameobjects array");
    _gameObjects = [[NSMutableArray alloc]init];
    
    //create and init player
  //  NSLog(@"initializing player");
    _player = [[PlayerObject alloc] init];
    [_gameObjectsToAdd addObject:_player];
    _player.position = GLKVector3Make(360.0f, 240.0f, 0.0f);
    
    
    // initisalize an enemy - may not be needed if spawned later
    _enemy = [[EnemyObject alloc] init];
   [_gameObjectsToAdd addObject:_enemy];
    _enemy.position = GLKVector3Make(32.0f, 1000.0f, 0.0f);

    
    //testing for dynamic enemy spawning
    NSLog(@"creating test objects");
    EnemyObject *myEnemy = [[EnemyObject alloc] init];
    [_gameObjectsToAdd addObject:myEnemy];
    myEnemy.position = GLKVector3Make(600.0f, 400.0f, 0.0f);

    
    //load map from file
    NSLog(@"loading map from file");
    _mapModel = [MapLoadHelper loadObjectsFromMap:@"map01"];
    [_gameObjectsToAdd addObjectsFromArray:_mapModel.objects];  //map number hardcoded for now
    
    //create initial "visible" list
    NSLog(@"creating initial visible objects array");
    _gameObjectsInView = [[NSMutableArray alloc]init];
    [self refreshGameObjectsInView];
    
    //create player move touch handler
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewportTap:)];
    [self.view addGestureRecognizer:tapGesture];
    
    NSLog(@"..done!");
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders]; //load original shader
    [self loadBGShaders]; //load background shader
    
    //useless GLKit stuff
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
    
    [self setupBackground]; //actually setup the background
    
    glEnable(GL_DEPTH_TEST);
    
    
    playerVert.length = sizeof(p2_pos) / 12;
    [self setupVertices:(VertexInfo*)&playerVert :p2_pos :p2_norm];
    
    enemyVert.length = sizeof(wizard_pos) / 12;
    [self setupVertices:(VertexInfo*)&enemyVert :wizard_pos :wizard_norm];
    
    arrowVert.length = sizeof(arrow_pos) / 12;
    [self setupVertices:(VertexInfo*)&arrowVert :arrow_pos :arrow_norm];
}

-(void)calculateRatios
{
    //calculate screen to viewport ratio
    //get rect
    //if we shrink or move the drawing view we may need a different rect
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    float screenWidth = screenRect.size.width;
    float screenHeight = screenRect.size.height;
    _screenToViewportX = VIEWPORT_WIDTH / screenWidth;
    _screenToViewportY = VIEWPORT_HEIGHT / screenHeight;
    _screenActualHeight = screenHeight;
    
}

-(void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    //teardown background
    glDeleteBuffers(1, &_bgVertexBuffer);
    glDeleteVertexArraysOES(1, &_bgVertexArray);
    
    //TODO Loop this
    //teardown vertex arrays and buffers
    glDeleteBuffers(1, &playerVert.vBuffer);
    glDeleteVertexArraysOES(1, &playerVert.vArray);
    
    glDeleteBuffers(1, &enemyVert.vBuffer);
    glDeleteVertexArraysOES(1, &enemyVert.vArray);
    
    self.effect = nil;
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

-(void)tearDownGame
{
    //may need to perform more extensive teardown on each game object
    [_gameObjects removeAllObjects];
    _gameObjects = nil;
}

//Michael
//Physics collision detection
//Each GameObject is a square with x,y position and a size
-(bool)checkCollisionBetweenObject:(GameObject *)one and:(GameObject *)two
{
    // check x-axis collision
    bool collisionX = one.position.x + one.size/2 >= two.position.x - two.size/2 && two.position.x + two.size/2 >= one.position.x - one.size/2;
    
    // check y-axis collision
    bool collisionY = one.position.y + one.size/2 >= two.position.y - two.size/2 && two.position.y + two.size/2 >= one.position.y - one.size/2;
    
    // collision occurs only if on both axes
    return collisionX && collisionY;
}

//Associate gameobjects with models
-(void)bindObject:(GameObject*)object
{

    //for debugging
    NSLog(@"Binding GL for: %@", NSStringFromClass([object class]));
    
    //determine model based on what the object is
    if([object isKindOfClass:[PlayerObject class]])
    {
        object.modelHandle = playerVert;
    }
    else if([object isKindOfClass:[EnemyObject class]])
    {
        object.modelHandle = enemyVert;
    }
    else if([object isKindOfClass:[ArrowObject class]])
    {
        object.modelHandle = arrowVert;
                
    }
    
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    //*****this is the "update" part of the loop
    
    [_gameObjectsInView removeAllObjects];
    
    //self.timeSinceLastUpdate
    
    //delete inactive gameobjects
    //turns out you can't delete during iteration in ObjC either
    //if this turns out to be too expensive, we can simply ignore disabled objects
    //and once every second or so, run a loop like this
    for(NSInteger i = _gameObjects.count - 1; i >= 0; i--)
    {
        GameObject *go = _gameObjects[i];
        if(!go.enabled)
        {
            [_gameObjects removeObjectAtIndex:i];
        }
    }
    
    //why not just pass _gameObjects into objectDataIn and use that directly?
    //something something safety, something something encapsulation, something something concurrency
    //if speed becomes an issue we can change it to do that
    //if we're careful with GameObject spawning we won't even have to touch the GameObjects
    for(id o in _gameObjectsToAdd)
    {
        [_gameObjects addObject:o];
         [self bindObject:o];
    }
    [_gameObjectsToAdd removeAllObjects];
    
    MBQObjectUpdateIn objectDataIn;
    
    //NSLog(@"%f",self.timeSinceLastUpdate);
    objectDataIn.timeSinceLast = self.timeSinceLastUpdate;
    objectDataIn.player = _player;
    objectDataIn.newObjectArray = _gameObjectsToAdd;
    objectDataIn.rightEdge = VIEWPORT_WIDTH;
    objectDataIn.topEdge = VIEWPORT_HEIGHT;
    
    //Denis: do we want to collide first, collide after, or collide during?
    
    for(id o in _gameObjects)
    {
     
        GameObject *go = (GameObject*)o;
        
        if([self isObjectInView:go])
        {
            [_gameObjectsInView addObject:go];
            objectDataIn.visibleOnScreen = YES;
        }
        else
        {
            objectDataIn.visibleOnScreen = NO;
        }
        
        
        [go update:&objectDataIn]; //each gameobject may do something during its update
        
        
        
    }
    
    //check for GameObject collisions
    //loop through all gameobjects in scene
    //check if any of those two objects are colliding AND they are both solid
    //if they are, then return collision!
    
    for (int i=0; i <_gameObjectsInView.count ; i++)
    {
        for (int j=0; j < _gameObjectsInView.count ; j++)
        {
            if ((((GameObject *)[_gameObjectsInView objectAtIndex:i]).solid && ((GameObject *)[_gameObjectsInView objectAtIndex:j]).solid) &&
                [self checkCollisionBetweenObject:_gameObjectsInView[i] and:_gameObjectsInView[j]]  && _gameObjectsInView[i] != _gameObjectsInView[j])
            {
                NSLog(@"Collision Detected!");
                [(GameObject *)_gameObjectsInView[i] onCollision:_gameObjectsInView[j]];
                //call oncollide function for first object only
                //still need to make the oncollide function
                
                AudioServicesPlaySystemSound(HitSfx);
            }
        }
    }
    
    //handle scrolling
    
    if(_scrolling)
    {
        NSLog(@"Scrolling: pos %.2f", _scrollPos);
        
        //if scrolling, continue moving while player is above lower bound threshold
        _scrollPos += SCROLL_SPEED;
        if(_player.position.y - _scrollPos < SCROLL_LOWER_BOUND)
        {
            _scrolling = false;
        }
        
    }
    else
    {
        //if player is within move threshold, start scrolling
        if(_player.position.y - _scrollPos > SCROLL_UPPER_BOUND)
        {
            _scrolling = true;
        }
        
    }

}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    //*****this is the "display" part of the loop
    
    //clear the display
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f); //set background color (I remember this from GDX)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); //clear

    //render the background
    [self renderBackground];
    
    MBQObjectDisplayIn objectDataIn;
    
    for(id o in _gameObjects)
    {
        if(((GameObject*)o).enabled && ((GameObject*)o).visible)
        {
            MBQObjectDisplayOut objectDisplayData = [o display:&objectDataIn];
            
            //TODO do something with the display data
            [self renderObject:(GameObject*)o];
        }
        
    }
    //what does this line do?
    glBindVertexArrayOES(enemyVert.vArray);
}

-(void)renderObject:(GameObject*)gameObject
{
    
    //glBindVertexArrayOES(data.modelHandle);
    glUseProgram(_program); //should probably provide options
    
    //float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    float aspect = fabs(VIEWPORT_WIDTH/VIEWPORT_HEIGHT);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(60.0f), aspect, 0.1f, 2000.0f);
    
    //self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(-360.0f, -640.0f-_scrollPos, -1108.0f); //fixed but can be calculated

    // Compute the model view matrix for the object rendered with ES2
    //GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 1.5f);
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(gameObject.position.x, gameObject.position.y, 1.5f);
    
   // modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
   // _rotation += self.timeSinceLastUpdate * 0.1f;
    
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, gameObject.rotation.x+gameObject.modelRotation.x, 1, 0,0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, gameObject.rotation.y+gameObject.modelRotation.y, 0, 1,0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, gameObject.rotation.z+gameObject.modelRotation.z, 0, 0,1);
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, gameObject.scale.x, gameObject.scale.y, gameObject.scale.z);
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, RENDER_MODEL_SCALE, RENDER_MODEL_SCALE, RENDER_MODEL_SCALE);
    //modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, 25.0f, 25.0f, 25.0f); //temp; should use object scale
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    
    //draw!
    
    //glBindVertexArrayOES(playerVert.vArray);
    glBindVertexArrayOES(gameObject.modelHandle.vArray);
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    
    
    // NSLog(@"moduleHandel array Size: %u", s);

    
    glDrawArrays(GL_TRIANGLES, 0, gameObject.modelHandle.length);//need to change 256 to actual array size
    
    //glDrawArrays(GL_TRIANGLES, 0, 1024); //will probably have to deal with this 36 somewhere
    
    
    glBindVertexArrayOES(0);
}

#pragma mark - Rendering methods

- (void)renderBackground
{
    //bg scroll pos should be scrollpos % bg length
    float bgScrollPos = fmodf(_scrollPos,_mapModel.backgroundLength);
    float bgLengthTransform;
    
    //draw once and then draw once ahead
    
    //create base matrix
    GLuint bgUloc = glGetUniformLocation(_bgProgram, "modelViewProjectionMatrix");
    GLKMatrix4 bgMvpm = GLKMatrix4Identity;
    GLKMatrix4 bgMvpm2;
    bgMvpm = GLKMatrix4MakeTranslation(-1.0f, -1.0f, 0.0f); //position the background
    bgMvpm = GLKMatrix4Scale(bgMvpm, 2.0f, _bgLengthScale, 1.0f); //scale the background
    
    //bind the background data in preparation to render
    glBindVertexArrayOES(_bgVertexArray);
    glUseProgram(_bgProgram);
    
    //texture setup
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _bgTexture);
    glUniform1i(_bgTexUniform, 0);

    //transform for first BG draw
    bgLengthTransform = (bgScrollPos / VIEWPORT_HEIGHT) / SCROLL_FACTOR;
    bgMvpm2 = GLKMatrix4Translate(bgMvpm, 0.0f, -bgLengthTransform, 0.0f); //scroll the background
    
    glUniformMatrix4fv(bgUloc, 1, 0, bgMvpm2.m);
    
    //draw it!
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    //repeat for the second BG draw
    bgLengthTransform = ((bgScrollPos-_mapModel.backgroundLength) / VIEWPORT_HEIGHT) / SCROLL_FACTOR;
    bgMvpm2 = GLKMatrix4Translate(bgMvpm, 0.0f, -bgLengthTransform, 0.0f); //scroll the background
    
    glUniformMatrix4fv(bgUloc, 1, 0, bgMvpm2.m);
    
    //draw it!
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    //clear the depth buffer so the background is behind everything
    glClear(GL_DEPTH_BUFFER_BIT);
}


#pragma mark - Touch and other event handlers

-(IBAction)handleViewportTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
    //get point, transform, and set player target
    CGPoint tapPoint =  [tapGestureRecognizer locationInView:nil]; //may need to specify view later
    MBQPoint2D scaledTapPoint = [self getPointInWorldSpace:tapPoint];
    [_player moveToTarget:scaledTapPoint];
}

- (IBAction)onToggleWeaponButton:(UIButton *)sender
{
    _player.isUsingWeapon = !_player.isUsingWeapon;
    
    if (_player.isUsingWeapon)
    {
        [_toggleWeaponButton setImage:_attackButtonWeaponImage forState:UIControlStateNormal];
    }
    else
    {
        [_toggleWeaponButton setImage:_attackButtonShieldImage forState:UIControlStateNormal];
    }
}


#pragma mark -  Rendering setup

//merges the positiona nd normal array and binds the model vertex info
-(void)setupVertices:(VertexInfo*)vertexInfoStruct :(GLfloat*)posArray : (GLfloat*)normArray
{
    glGenVertexArraysOES(1, &vertexInfoStruct->vArray);
    glBindVertexArrayOES(vertexInfoStruct->vArray);
    
    glGenBuffers(1, &vertexInfoStruct->vBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexInfoStruct->vBuffer);

    long size = playerVert.length * 6;
    GLfloat mixedArray[size];
    int j = 0;
    int k = 0;
    for(int i = 0; i < size; i++){
        //NSLog(@"%u", i%6);
        if(i%6 < 3){
            mixedArray[i] = posArray[j];
            j++;
        }else{
            mixedArray[i] = normArray[k];
            k++;
        }
        //NSLog(@"%.2f", mixedArray[i]);
    }
    
    //load array into buffer
    glBufferData(GL_ARRAY_BUFFER, sizeof(mixedArray), mixedArray, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    
    glBindVertexArrayOES(0);

}


- (void)setupBackground
{
    //load background
    _bgTexture = [self setupTexture:_mapModel.background];
    _bgLengthScale = 2.0f * (_mapModel.backgroundLength / VIEWPORT_HEIGHT); //deal with different sized backgrounds
    
    //TODO move this
    GLfloat bgVertices[] = {
        0.0f, 0.0f, 0.1f,
        0.0f, 1.0f, 0.1f,
        1.0f, 0.0f, 0.1f,
        0.0f, 1.0f, 0.1f,
        1.0f, 0.0f, 0.1f,
        1.0f, 1.0f, 0.1f  };
    
    glGenVertexArraysOES(1, &_bgVertexArray);
    glBindVertexArrayOES(_bgVertexArray);
    glGenBuffers(1, &_bgVertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _bgVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(bgVertices), bgVertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 12, BUFFER_OFFSET(0));
    
    _bgTexCoordSlot = glGetAttribLocation(_bgProgram, "texCoordIn");
    glEnableVertexAttribArray(_bgTexCoordSlot);
    _bgTexUniform = glGetUniformLocation(_bgProgram, "texture");
    glVertexAttribPointer(_bgTexCoordSlot, 2, GL_FLOAT, GL_FALSE, 12, BUFFER_OFFSET(0));
    
    glBindVertexArrayOES(0);
}



#pragma mark -  OpenGL ES 2 shader compilation
//TODO: unified shader loading and storage

//load/compile background shaders
- (BOOL)loadBGShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _bgProgram = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"BGShader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"BGShader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_bgProgram, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_bgProgram, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_bgProgram, GLKVertexAttribPosition, "position");
    
    
    // Link program.
    if (![self linkProgram:_bgProgram]) {
        NSLog(@"Failed to link program: %d", _bgProgram);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_bgProgram) {
            glDeleteProgram(_bgProgram);
            _bgProgram = 0;
        }
        
        return NO;
    }
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_bgProgram, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_bgProgram, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
    glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

#pragma mark -  OpenGL ES 2 textures and stuff

-(GLuint)setupTexture:(NSString *)fileName {

    //load CGimage
    CGImageRef cgTexImage = [UIImage imageNamed:fileName].CGImage;
    if(!cgTexImage)
    {
        NSLog(@"Failed to load texture(%@)", fileName);
        return NO;
    }
    
    //allocate and create context
    size_t w = CGImageGetWidth(cgTexImage);
    size_t h = CGImageGetHeight(cgTexImage);
    GLubyte *glTexData = (GLubyte*) calloc(w*h*4, sizeof(GLubyte));
    CGContextRef cgTexContext = CGBitmapContextCreate(glTexData, w, h, 8, w*4,                                                      CGImageGetColorSpace(cgTexImage), kCGImageAlphaPremultipliedLast);
    
    
    //draw into context with CG (and flip)
    CGContextTranslateCTM(cgTexContext, 0, h);
    CGContextScaleCTM(cgTexContext, 1.0, -1.0);
    CGContextDrawImage(cgTexContext, CGRectMake(0,0,w,h), cgTexImage);
    CGContextRelease(cgTexContext);
    
    
    //bind GL texture
    GLuint glTexName;
    glGenTextures(1, &glTexName);
    glBindTexture(GL_TEXTURE_2D, glTexName);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, glTexData);
    
    free(glTexData);
    return glTexName;
}

#pragma mark - MBQ utility methods

-(MBQPoint2D)getPointInWindowSpace:(CGPoint)ssPoint
{
    MBQPoint2D wsPoint;
    
    //do the actual conversion
    
    //x is normal but y needs to be flipped
    wsPoint.x = ssPoint.x * _screenToViewportX;
    wsPoint.y = (_screenActualHeight - ssPoint.y) * _screenToViewportY;
    
    return wsPoint;
}

-(MBQPoint2D)getPointInWorldSpace:(CGPoint)ssPoint
{
    MBQPoint2D wsPoint;
    
    wsPoint = [self getPointInWindowSpace:ssPoint];
    
    wsPoint.y = wsPoint.y + _scrollPos;
    
    return wsPoint;
}
//TODO: if we need to go the other way

//possible optimization: check objects in view every second or so, move in and out of "visible" list
//this might be needed to get decent physics performance
-(BOOL)isObjectInView:(GameObject*)object
{
    //TODO: optimize with short-circuit to deal with most likely conditions
    //actually check if object is within view (view bounds)
    float objX = object.position.x;
    float objY = object.position.y - _scrollPos;
    BOOL withinX = objX > (0 - VIEWPORT_OVERSCAN) && objX < (VIEWPORT_WIDTH + VIEWPORT_OVERSCAN);
    BOOL withinY = objY > (0 - VIEWPORT_OVERSCAN) && objY < (VIEWPORT_HEIGHT + VIEWPORT_OVERSCAN);
    
    return withinX && withinY;
}

//this should work
-(void)refreshGameObjectsInView
{
    [_gameObjectsInView removeAllObjects];
    
    for(id o in _gameObjects)
    {
        if([self isObjectInView:((GameObject*)o)])
        {
            [_gameObjectsInView addObject:o];
        }
    }
}

@end
