//
//  Shader.fsh
//  minibattlequest
//
//  Created by Chris Leclair on 2017-01-24.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
