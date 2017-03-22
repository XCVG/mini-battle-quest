//
//  Shader.fsh
//  minibattlequest
//
//  Created by Chris Leclair on 2017-01-24.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//
/*
varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
*/

precision mediump float;

varying vec3 eyeNormal;
varying vec4 eyePos;
varying vec2 texCoordOut;
/* set up a uniform sampler2D to get texture */
uniform sampler2D texture;

/* set up uniforms for lighting parameters */
uniform vec3 flashlightPosition;
uniform vec3 diffuseLightPosition;
uniform vec4 diffuseComponent;
uniform float shininess;
uniform vec4 specularComponent;
uniform vec4 ambientComponent;
uniform vec4 fogIntensity; //0 to 1
uniform vec4 fogColor;

void main()
{
    vec4 ambient = ambientComponent;
    vec3 N = normalize(-eyeNormal);
    float nDotVP = max(0.0, dot(N, normalize(diffuseLightPosition)));
    vec4 diffuse = diffuseComponent * nDotVP;
    
    vec3 E = normalize(-eyePos.xyz);
    vec3 L = normalize(flashlightPosition - eyePos.xyz);
    vec3 H = normalize(L+E);
    float Ks = pow(max(dot(N, H), 0.0), shininess);
    vec4 specular = Ks*specularComponent;
    
    
    if( dot(L, N) < 0.0 ) {
        specular = vec4(0.0, 0.0, 0.0, 1.0);
    }
    
    //vec4 fogColor = vec4(0.5, 0.5, 0.5, 1.0);
    vec4 finalColor = (ambient + diffuse + specular) * texture2D(texture, texCoordOut);
    vec4 fogDiff =  fogColor - finalColor;
    fogDiff = fogDiff * fogIntensity;
    finalColor = fogDiff + finalColor;
    gl_FragColor = finalColor;
    gl_FragColor.a = 1.0;
    
}
