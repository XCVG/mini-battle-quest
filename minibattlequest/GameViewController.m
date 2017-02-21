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
#import "MeeseeksObject.h"
#import "SpambotObject.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

#define VIEWPORT_WIDTH 720.0f
#define VIEWPORT_HEIGHT 1280.0f

#define VIEWPORT_OVERSCAN 100.0f

#define SCROLL_UPPER_BOUND 800.0f
#define SCROLL_LOWER_BOUND 200.0f
#define SCROLL_SPEED 50.0f



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

GLfloat gCubeVertexData[216] = 
{
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,
    0.5f, -0.5f, -0.5f,        1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,          1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    
    0.5f, 0.5f, -0.5f,         0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 1.0f, 0.0f,
    
    -0.5f, 0.5f, -0.5f,        -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        -1.0f, 0.0f, 0.0f,
    
    -0.5f, -0.5f, -0.5f,       0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         0.0f, -1.0f, 0.0f,
    
    0.5f, 0.5f, 0.5f,          0.0f, 0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, 0.0f, 1.0f,
    
    0.5f, -0.5f, -0.5f,        0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 0.0f, -1.0f
};

@interface GameViewController () {
    GLuint _program;
    //TODO: completely redo the way shaders/programs are referenced and handled
    GLuint _bgProgram;
    GLuint _bgVertexArray;
    GLuint _bgVertexBuffer;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    float _rotation;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

-(void)handleViewportTap:(UITapGestureRecognizer *)tapGestureRecognizer;
- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

@end

@implementation GameViewController {
    
    //game variables
    NSMutableArray *_gameObjects;
    PlayerObject *_player;
    NSMutableArray *_gameObjectsInView;
    NSMutableArray *_gameObjectsToAdd;
    
    float _scrollPos;
    BOOL _scrolling;
    
    BOOL _running;
    
    
    //viewport pseudoconstants
    float _screenToViewportX;
    float _screenToViewportY;
    float _screenActualHeight;
    
    
    
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
    
    NSLog(@"creating gameobjects array");
    _gameObjects = [[NSMutableArray alloc]init];
    
    //create and init player
    NSLog(@"initializing player");
    _player = [[PlayerObject alloc] init];
    [_gameObjects addObject:_player];
    
    //for testing: Meseeks and Spawner
    NSLog(@"creating test objects");
    [_gameObjects addObject:[[MeeseeksObject alloc] init] ];
    [_gameObjects addObject:[[SpambotObject alloc] init] ];
    
    //load map from file
    NSLog(@"loading map from file");
    MapModel* mapModel = [MapLoadHelper loadObjectsFromMap:@"map01"];
    [_gameObjects addObjectsFromArray:mapModel.objects];  //map number hardcoded for now
    
    //create initial "visible" list
    NSLog(@"creating initial visible objects array");
    _gameObjectsInView = [[NSMutableArray alloc]init];
    [self refreshGameObjectsInView];
    
    NSLog(@"creating 'objects to add' array");
    _gameObjectsToAdd = [[NSMutableArray alloc] init];
    
    //create player move touch handler
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewportTap:)];
    [self.view addGestureRecognizer:tapGesture];
    
    NSLog(@"..done!");
}

- (void)setupGL
{
    NSLog(@"Opening GL...");
    
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    [self loadBGShaders];
    
    //useless GLKit stuff
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
    
    //load background
    
    //TODO move this
    GLfloat bgVertices[] = {
        0.0f, 0.0f, 0.2f,
        0.0f, 1.0f, 0.2f,
        1.0f, 0.0f, 0.2f,
        0.0f, 1.0f, 0.2f,
        1.0f, 0.0f, 0.2f,
        1.0f, 1.0f, 0.2f  };
    
    glGenVertexArraysOES(1, &_bgVertexArray);
    glBindVertexArrayOES(_bgVertexArray);
    glGenBuffers(1, &_bgVertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _bgVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(bgVertices), bgVertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 6, BUFFER_OFFSET(0));
    
    
    
    glBindVertexArrayOES(0);
    
    
    
    //load cube
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    
    glBindVertexArrayOES(0);
    
    NSLog(@"...done!");
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

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
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
        [_gameObjectsToAdd removeObject:o];
    }
    
    MBQObjectUpdateIn objectDataIn;
    
    //NSLog(@"%f",self.timeSinceLastUpdate);
    objectDataIn.timeSinceLast = self.timeSinceLastUpdate;
    objectDataIn.player = _player;
    objectDataIn.newObjectArray = _gameObjectsToAdd;
    
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
    
    //TODO other functionality
    
    
    //stuff below is for demo, should remove it
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f);
    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, _rotation, 0.0f, 1.0f, 0.0f);
    
    // Compute the model view matrix for the object rendered with GLKit
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    
    // Compute the model view matrix for the object rendered with ES2
    modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    _rotation += self.timeSinceLastUpdate * 0.5f;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    //*****this is the "display" part of the loop
    
    //clear the display
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f); //set background color (I remember this from GDX)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); //clear
    
    /*
    {
        glUseProgram(_program);
        
        GLfloat square[] = {
            -0.5, -0.5,
            0.5, -0.5,
            -0.5, 0.5,
            0.5, 0.5};
        
        const char *aPositionCString = [@"position" cStringUsingEncoding:NSUTF8StringEncoding];
        GLuint aPosition = glGetAttribLocation(_program, aPositionCString);
        
        glVertexAttribPointer(aPosition, 2, GL_FLOAT, GL_FALSE, 0, square);
        glEnableVertexAttribArray(aPosition);
        
        // Draw
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    */
    
    {
        glBindVertexArrayOES(_bgVertexArray);
        glUseProgram(_bgProgram);
        
        //matrix stuff
        GLuint bgUloc = glGetUniformLocation(_bgProgram, "modelViewProjectionMatrix");
        
        GLKMatrix4 bgMvpm = GLKMatrix4Identity;
        bgMvpm = GLKMatrix4MakeTranslation(1.0f, -1.0f, 0.0f);
        bgMvpm = GLKMatrix4Scale(bgMvpm, 1.0f, 2.0f, 1.0f);
        
        glUniformMatrix4fv(bgUloc, 1, 0, bgMvpm.m);
        
        
        glDrawArrays(GL_TRIANGLES, 0, 6);
        
    }
    
    glClear(GL_DEPTH_BUFFER_BIT);
    
    MBQObjectDisplayIn objectDataIn;
    
    for(id o in _gameObjectsInView)
    {
        if(((GameObject*)o).enabled && ((GameObject*)o).visible)
        {
            MBQObjectDisplayOut objectDisplayData = [o display:&objectDataIn];
            
            //TODO do something withthe display data
        }
        
    }
    
    glBindVertexArrayOES(_vertexArray);
    
    // Render the object with GLKit
    //[self.effect prepareToDraw];
    
    //glDrawArrays(GL_TRIANGLES, 0, 36);
    
    // Render the object again with ES2
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    
    glDrawArrays(GL_TRIANGLES, 0, 36);
}

#pragma mark - Touch and other event handlers

-(IBAction)handleViewportTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
    //get point, transform, and set player target
    CGPoint tapPoint =  [tapGestureRecognizer locationInView:nil]; //may need to specify view later
    MBQPoint2D scaledTapPoint = [self getPointInWorldSpace:tapPoint];
    [_player moveToTarget:scaledTapPoint];
}

#pragma mark -  OpenGL ES 2 shader compilation
//I have no idea what ANY of this does
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
