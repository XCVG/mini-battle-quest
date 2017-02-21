//
//  BGShader.vsh
//  minibattlequest
//
//  Created by Chris Leclair on 2017-01-24.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

//based on dead simple vertex shader
attribute vec4 position;

void main()
{
    gl_Position = position;
}
