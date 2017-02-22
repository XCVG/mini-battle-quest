//
//  BGShader.vsh
//  minibattlequest
//
//  Created by Chris Leclair on 2017-01-24.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

//based on dead simple vertex shader
attribute vec4 position;

attribute vec2 texCoordIn;
varying vec2 texCoordOut;

uniform mat4 modelViewProjectionMatrix;

void main()
{
    gl_Position = modelViewProjectionMatrix * position;
    texCoordOut = texCoordIn;
}
