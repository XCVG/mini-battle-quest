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

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#import "MBQDataManager.h"
#import "LeaderboardScore+Util.h"

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


// Shader uniform indices
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    UNIFORM_MODELVIEW_MATRIX,
    UNIFORM_TEXTURE,
    UNIFORM_FLASHLIGHT_POSITION,
    UNIFORM_DIFFUSE_LIGHT_POSITION,
    UNIFORM_SHININESS,
    UNIFORM_AMBIENT_COMPONENT,
    UNIFORM_DIFFUSE_COMPONENT,
    UNIFORM_SPECULAR_COMPONENT,
    UNIFORM_FOG_COLOR,
    UNIFORM_FOG_INTENSITY,
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
    
    VertexInfo fireBallVert, arrowVert;
    
    // Lighting parameters
    GLKVector3 flashlightPosition;
    GLKVector3 diffuseLightPosition;
    GLKVector4 diffuseComponent;
    float shininess;
    GLKVector4 specularComponent;
    GLKVector4 ambientComponent;
    GLKVector4 fogColor, fogIntensity;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

@property (weak, nonatomic) IBOutlet UIButton *toggleWeaponButton;
@property (weak, nonatomic) IBOutlet UIProgressView *playerHealthBar;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;

@property (strong, nonatomic) AVAudioPlayer *backgroundMusic;

-(void)handleViewportTap:(UITapGestureRecognizer *)tapGestureRecognizer;
- (void)setupGL;
- (void)tearDownGL;
- (bool)CheckCollision;
- (void)endRound;
- (void)savePlayerScore;

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
    GameObject *_shield;
    GameObject *_bow;
    float shieldOffset;
    float bowOffset;
    NSMutableArray *_gameObjectsInView;
    NSMutableArray *_gameObjectsToAdd;
    
    float _scrollPos;
    BOOL _scrolling;
    
    BOOL _running;
    
    int _playerScore;
    
    //viewport pseudoconstants
    float _screenToViewportX;
    float _screenToViewportY;
    float _screenActualHeight;
    
    NSURL *bgMusicPath;
    
    SystemSoundID BowEquipSfx;
    SystemSoundID ShieldEquipSfx;
    
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
    
    NSString *bowEquipSoundPath = [[NSBundle mainBundle] pathForResource:@"BowEquip" ofType:@"mp3"];
    NSURL *bowEquipSoundPathURL = [NSURL fileURLWithPath : bowEquipSoundPath];
    
    NSString *shieldEquipSoundPath = [[NSBundle mainBundle] pathForResource:@"ShieldEquip" ofType:@"mp3"];
    NSURL *shieldEquipSoundPathURL = [NSURL fileURLWithPath : shieldEquipSoundPath];
    
    bgMusicPath = [[NSBundle mainBundle] URLForResource:@"ValiantWind" withExtension:@"mp3"];
    self.backgroundMusic = [[AVAudioPlayer alloc] initWithContentsOfURL:bgMusicPath error:nil];
    self.backgroundMusic.numberOfLoops = -1;
    [self.backgroundMusic play];
    
    //create audio
    AudioServicesCreateSystemSoundID((__bridge CFURLRef) bowEquipSoundPathURL, &BowEquipSfx);
    AudioServicesCreateSystemSoundID((__bridge CFURLRef) shieldEquipSoundPathURL, &ShieldEquipSfx);
    
    /* Get attack button images. */
    _attackButtonWeaponImage = [UIImage imageNamed:@"mbq_img_button_action_bow.png"];
    _attackButtonShieldImage = [UIImage imageNamed:@"mbq_img_button_action_shield.png"];
}

- (void)dealloc
{
    [self tearDownGame];
    [self tearDownGL];
    
    AudioServicesDisposeSystemSoundID(BowEquipSfx);
    AudioServicesDisposeSystemSoundID(ShieldEquipSfx);
    
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

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self savePlayerScore];
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
    _player.modelName = @"player";
    _player.textureName = @"Player_Texture.png";
    
    _shield = [[GameObject alloc] init];
    [_gameObjectsToAdd addObject:_shield];
    _shield.rotation = GLKVector3Make(1.0f,0,0);
    _shield.scale = GLKVector3Make(50.0f, 50.0f, 50.0f);
    _shield.modelName = @"Shield";
    _shield.textureName = @"Shield_Texture.png";
    shieldOffset = 50.0f;
    
    _bow = [[GameObject alloc] init];
    [_gameObjectsToAdd addObject:_bow];
    _bow.rotation = GLKVector3Make(0,1.0f,0);
    _bow.scale = GLKVector3Make(40.0f, 40.0f, 40.0f);
    _bow.modelName = @"Bow";
    _bow.textureName = @"Bow_Texture.png";
    bowOffset = -30.0f;
    
    //load map from file
    NSLog(@"loading map from file");
    _mapModel = [MapLoadHelper loadObjectsFromMap:@"map01"];
    [_gameObjectsToAdd addObjectsFromArray:_mapModel.objects];  //map number hardcoded for now
    
    //create initial "visible" list
    NSLog(@"creating initial visible objects array");
    _gameObjectsInView = [[NSMutableArray alloc]init];
    [self refreshGameObjectsInView];
    
    //create player move touch hand.ler
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewportTap:)];
    [self.view addGestureRecognizer:tapGesture];
    
    NSLog(@"..done!");
}

/**
    End the round and record the player's score when the player dies.
 */
- (void) endRound
{
    /* Return to the main menu. */
    [self.navigationController popToRootViewControllerAnimated:YES];
}

/**
    Save the player's current score to the database.
 */
- (void)savePlayerScore
{
    [[MBQDataManager instance] performWithDocument:^(UIManagedDocument *document) {
        [LeaderboardScore addScoreWithValue:_playerScore inManagedObjectContext:document.managedObjectContext];
    }];
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
   
 
    
     [self loadShaders]; //load original shader
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    uniforms[UNIFORM_MODELVIEW_MATRIX] = glGetUniformLocation(_program, "modelViewMatrix");
    
    uniforms[UNIFORM_TEXTURE] = glGetUniformLocation(_program, "texture");
    uniforms[UNIFORM_FLASHLIGHT_POSITION] = glGetUniformLocation(_program, "flashlightPosition");
    uniforms[UNIFORM_DIFFUSE_LIGHT_POSITION] = glGetUniformLocation(_program, "diffuseLightPosition");
    uniforms[UNIFORM_SHININESS] = glGetUniformLocation(_program, "shininess");
    uniforms[UNIFORM_AMBIENT_COMPONENT] = glGetUniformLocation(_program, "ambientComponent");
    uniforms[UNIFORM_DIFFUSE_COMPONENT] = glGetUniformLocation(_program, "diffuseComponent");
    uniforms[UNIFORM_SPECULAR_COMPONENT] = glGetUniformLocation(_program, "specularComponent");
    uniforms[UNIFORM_FOG_INTENSITY] = glGetUniformLocation(_program, "fogIntensity");
    uniforms[UNIFORM_FOG_COLOR] = glGetUniformLocation(_program, "fogColor");
    
    // Set up lighting parameters
    flashlightPosition = GLKVector3Make(0.0, 0.0, 0.1f);
    diffuseLightPosition = GLKVector3Make(1.0, 1.0, 1.0);
    diffuseComponent = GLKVector4Make(0.4, 0.8, 0.4, 1.0);
    shininess = 50.0;
    fogIntensity = GLKVector4Make(0, 0, 0, 1.0);
    fogColor = GLKVector4Make(0.5f, 0.5f, 0.5f, 1);
    ambientComponent = GLKVector4Make(0.5, 0.5, 0.5, 1.0);
    
    [self loadBGShaders]; //load background shader
    
    [self setupBackground]; //actually setup the background
    
    glEnable(GL_DEPTH_TEST);
    

    //setup vertex buffers for projectiles so you don't have to remake them every time you shoot
    arrowVert = [self loadModel :@"Arrow" :@"crate.jpg"];
    fireBallVert = [self loadModel :@"Fireball" :@"Fireball_Texture.png"];
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
    
   // glDeleteBuffers(1, &playerVert.vBuffer);
    //glDeleteVertexArraysOES(1, &playerVert.vArray);
    

    
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

    NSLog(@"Binding GL for: %@", NSStringFromClass([object class]));
    if([object.modelName  isEqual: @"Arrow"]){
        object.modelHandle = arrowVert;
    }else if([object.modelName  isEqual: @"Fireball"]){
        object.modelHandle = fireBallVert;
    }else{
        object.modelHandle = [self loadModel :object.modelName :object.textureName];
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
            if (go == _player)
            {
                [self endRound];
            }

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

    /* Update player health bar. */
    [_playerHealthBar setProgress:(_player.health / _player.maxHealth)];
    
    /* Update score label. */
    _playerScore = (int)_player.position.y;
    [_scoreLabel setText:[NSString stringWithFormat:@"Score: %i", _playerScore]];
    
    /* Update Weapon positions relative to player's position. */
    _bow.position = GLKVector3Make(_player.position.x, _player.position.y + bowOffset, _player.position.z);
    _shield.position = GLKVector3Make(_player.position.x, _player.position.y + shieldOffset, _player.position.z);
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
}

-(void)renderObject:(GameObject*)gameObject
{
    
    glBindVertexArrayOES(gameObject.modelHandle.vArray);
    glUseProgram(_program); //should probably provide options
    
    //float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    float aspect = fabs(VIEWPORT_WIDTH/VIEWPORT_HEIGHT);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(60.0f), aspect, 0.1f, 2000.0f);
    
    //self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(-360.0f, -640.0f-_scrollPos, -1108.0f); //fixed but can be calculated

    // Compute the model view matrix for the object rendered with ES2
    //GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 1.5f);
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(gameObject.position.x, gameObject.position.y, 1.5f);
    
    if([gameObject isKindOfClass:[ArrowObject class]]){
        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 0.0f, 1.0f, 0.0f);
        _rotation += self.timeSinceLastUpdate * 2.0f;

    }
    
    
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, gameObject.scale.x, gameObject.scale.y, gameObject.scale.z);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, gameObject.rotation.x+gameObject.modelRotation.x, 1, 0,0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, gameObject.rotation.y+gameObject.modelRotation.y, 0, 1,0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, gameObject.rotation.z+gameObject.modelRotation.z, 0, 0,1);
    
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, RENDER_MODEL_SCALE, RENDER_MODEL_SCALE, RENDER_MODEL_SCALE);
    //modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, 25.0f, 25.0f, 25.0f); //temp; should use object scale
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    // Set up uniforms
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniform3fv(uniforms[UNIFORM_FLASHLIGHT_POSITION], 1, flashlightPosition.v);
    glUniform3fv(uniforms[UNIFORM_DIFFUSE_LIGHT_POSITION], 1, diffuseLightPosition.v);
    glUniform4fv(uniforms[UNIFORM_DIFFUSE_COMPONENT], 1, diffuseComponent.v);
    glUniform1f(uniforms[UNIFORM_SHININESS], shininess);
    glUniform4fv(uniforms[UNIFORM_SPECULAR_COMPONENT], 1, specularComponent.v);
    glUniform4fv(uniforms[UNIFORM_AMBIENT_COMPONENT], 1, ambientComponent.v);
    glUniform4fv(uniforms[UNIFORM_FOG_INTENSITY], 1, fogIntensity.v);
    glUniform4fv(uniforms[UNIFORM_FOG_COLOR], 1, fogColor.v);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, gameObject.modelHandle.textureHandle);
    glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
    
    //draw!
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gameObject.modelHandle.vBuffer);
    glDrawArrays(GL_TRIANGLES, 0, gameObject.modelHandle.length);
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
        AudioServicesPlaySystemSound(BowEquipSfx);
        
        //Put bow infront, and but shield on your back
        _bow.rotation = GLKVector3Make(1.0f,0,0.5f);
        _bow.scale = GLKVector3Make(50.0f, 50.0f, 50.0f);
        bowOffset = 25.0f;
        
        _shield.rotation = GLKVector3Make(1.0f,0,0);
        _shield.scale = GLKVector3Make(40.0f, 40.0f, 40.0f);
        shieldOffset = -30.0f;
    }
    else
    {
        [_toggleWeaponButton setImage:_attackButtonShieldImage forState:UIControlStateNormal];
        AudioServicesPlaySystemSound(ShieldEquipSfx);
        
        //Put shield infront, and but bow on your back
        _shield.rotation = GLKVector3Make(1.0f,0,0);
        _shield.scale = GLKVector3Make(50.0f, 50.0f, 50.0f);
        shieldOffset = 50.0f;
        
        _bow.rotation = GLKVector3Make(0,1.0f,0);
        _bow.scale = GLKVector3Make(40.0f, 40.0f, 40.0f);
        bowOffset = -30.0f;
    }
}

#pragma mark -  Rendering setup
/*
 Loads model vtnf arrays from the obj file, and sets up the vertex buffer, and uses the provided image for texture
 Parameters:
 filename - string file name of the obj model - DON'T INCLUDE THE EXTENSION!(ie "crate" instead of "crate.obj")
 textureName - string name of the texture image file - this one should have the extension included
 */
-(VertexInfo)loadModel :(NSString*) fileName :(NSString*) textureName
{
    NSString* fileRoot = [[NSBundle mainBundle]
                          pathForResource:fileName ofType:@"obj"];
    
    NSString* fileContents =
    [NSString stringWithContentsOfFile:fileRoot
                              encoding:NSUTF8StringEncoding error:nil];
    
    // separate by new line
    NSArray* allLinedStrings =
    [fileContents componentsSeparatedByCharactersInSet:
     [NSCharacterSet newlineCharacterSet]];
    
    
    int tLength = 0;
    int vLength = 0;
    int nLength = 0;
    int fLength = 0;
    
    //determine the length of the vtnf arrays
    for (NSString* line in allLinedStrings) {
        if (line.length > 1 && [line characterAtIndex:0] == 'v' && [line characterAtIndex:1] == 't') {
            tLength+= 2;
        }
        else if (line.length > 1 && [line characterAtIndex:0] == 'v' && [line characterAtIndex:1] == 'n') {
            nLength+= 3;
        }
        else if (line.length > 1 && [line characterAtIndex:0] == 'v' && [line characterAtIndex:1] == ' ') {
            vLength+= 3;
        }
        else if (line.length > 1 && [line characterAtIndex:0] == 'f'){
            
            fLength+= 9;
        }
    }
    float vArray[vLength];
    float nArray[nLength];
    float tArray[tLength];
    int fArray[fLength];
    int tCount = 0;
    int vCount = 0;
    int nCount = 0;
    int fCount = 0;
    int i = 0;
    NSScanner *scanner;

    //populate the vtnf arrays with values from the obj file
    for (NSString* line in allLinedStrings) {
        scanner = [NSScanner scannerWithString:line];
        
        if (line.length > 1 && [line characterAtIndex:0] == 'v' && [line characterAtIndex:1] == 't') {
            [scanner scanUpToString:@" " intoString:NULL];
            
            for(i = 0; i < 2; i++){
                [scanner setScanLocation:[scanner scanLocation] + 1];
                [scanner scanFloat:&tArray[tCount]];
                tCount++;
            }
        }
        else if (line.length > 1 && [line characterAtIndex:0] == 'v' && [line characterAtIndex:1] == 'n') {
            [scanner scanUpToString:@" " intoString:NULL];
            
            for(i = 0; i < 3; i++){
                [scanner setScanLocation:[scanner scanLocation] + 1];
                [scanner scanFloat:&nArray[nCount]];
                nCount++;
            }
        }
        else if (line.length > 1 && [line characterAtIndex:0] == 'v' && [line characterAtIndex:1] == ' ') {
            [scanner scanUpToString:@" " intoString:NULL];
            
            for(i = 0; i < 3; i++){
                [scanner setScanLocation:[scanner scanLocation] + 1];
                [scanner scanFloat:&vArray[vCount]];
                vCount++;
            }
            
        }
        else if (line.length > 1 && [line characterAtIndex:0] == 'f'){
            [scanner scanUpToString:@" " intoString:NULL];
            
            for(i = 0; i <9; i++){
                [scanner setScanLocation:[scanner scanLocation] + 1];
                [scanner scanInt:&fArray[fCount]];
                fCount++;
            }
        }
    }
    //build the combined vnt array based on the vertices specified in the fArray
    float mixedArray[(fLength/3)*8];
    int mCount = 0;
    vCount = 0;
    tCount = 0;
    nCount = 0;
    tCount = 0;
    for(i=0; i < fLength; i++){
        if(i%3 == 0){
            mixedArray[mCount] = vArray[(fArray[i]-1)*3];
            mCount++;
            mixedArray[mCount] = vArray[(fArray[i]-1)*3 + 1];
            mCount++;
            mixedArray[mCount] = vArray[(fArray[i]-1)*3 + 2];
            mCount++;
        }
        else if(i%3 == 2){
            mixedArray[mCount] = nArray[(fArray[i]-1)*3];
            mCount++;
            mixedArray[mCount] = nArray[(fArray[i]-1)*3 + 1];
            mCount++;
            mixedArray[mCount] = nArray[(fArray[i]-1)*3 + 2];
            mCount++;
        }
        else if(i%3 == 1){
            mixedArray[mCount] = tArray[(fArray[i]-1)*2];
            mCount++;
            mixedArray[mCount] = 1-tArray[(fArray[i]-1)*2 + 1];
            mCount++;
        }
    }
    
    VertexInfo vertexInfoStruct;
    vertexInfoStruct.length = fLength/3;
    //NSLog(@"%u", vertexInfoStruct.length);
    
    glGenVertexArraysOES(1, &vertexInfoStruct.vArray);
    glBindVertexArrayOES(vertexInfoStruct.vArray);
    
    glGenBuffers(1, &vertexInfoStruct.vBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexInfoStruct.vBuffer);
    
    //load array into buffer
    glBufferData(GL_ARRAY_BUFFER, sizeof(mixedArray), mixedArray, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(0));
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(12));
    
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(20));
    
    
    glBindVertexArrayOES(0);
    
    // Load in and set texture
    vertexInfoStruct.textureHandle = [self setupTexture:textureName];
    
    return vertexInfoStruct;
    
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
    glBindAttribLocation(_program, GLKVertexAttribTexCoord0, "texCoordIn");
    
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
//old setup texture function (left it here incase new one will cause trouble with background - Denis
/*
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
 */
- (GLuint)setupTexture:(NSString *)fileName
{
    //NSLog(@"Loading texture %@", fileName);
    
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte *spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    return texName;
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
