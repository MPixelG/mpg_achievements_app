precision mediump float;
#include <flutter/runtime_effect.glsl>

uniform sampler2D albedoMap;
uniform sampler2D depthMap;
uniform vec2 screenSize;

out vec4 fragColor;

void main() {


    vec2 uv = FlutterFragCoord().xy / screenSize;

    vec4 depthMapPixel = texture(depthMap, uv);
    vec2 twoChannelNormalVal = depthMapPixel.rg;

    vec3 normalVal = vec3(twoChannelNormalVal, sqrt(max(0, 1 - depthMapPixel.x*depthMapPixel.x - depthMapPixel.y*depthMapPixel.y)));

    float height = depthMapPixel.b;


    fragColor = depthMapPixel;
}