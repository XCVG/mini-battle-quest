//
//  BGShader.fsh
//  minibattlequest
//
//  Created by Chris Leclair on 2017-01-24.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

//carbon copy of default Shader for now, will figure out textures later
varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
