#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform sampler2D mapData;
uniform sampler2D tileset;
uniform sampler2D normalMapTileset;

uniform int layerWidth;
uniform int layerHeight;
uniform int zLayers;

out vec4 fragColor;

void main() {
    fragColor = vec4(textureColor.rgb * diff * globalLightColor, textureColor.a);
}