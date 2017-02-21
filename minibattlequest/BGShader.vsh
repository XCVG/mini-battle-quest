//
//  BGShader.vsh
//  minibattlequest
//
//  Created by Chris Leclair on 2017-01-24.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

//based on dead simple vertex shader
attribute vec4 position;

uniform mat4 modelViewProjectionMatrix;

void main()
{
    gl_Position = modelViewProjectionMatrix * position;
}
