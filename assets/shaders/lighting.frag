precision mediump float;
#include <flutter/runtime_effect.glsl>

uniform sampler2D albedoMap;
uniform sampler2D depthMap;
uniform vec2 screenSize;
uniform vec2 lightPos;

out vec4 fragColor;

vec2 iso2orth(vec3 iso, float heightScale) {
    float sum = iso.y / heightScale + iso.z;
    float diff = iso.x;
    float x = (sum + diff) * 0.5;
    float y = (sum - diff) * 0.5;
    return vec2(x, y);
}


void main() {
    vec2 uv = FlutterFragCoord().xy / screenSize;

    vec4 depthMapPixel = texture(depthMap, uv);
    vec2 nxy = depthMapPixel.rg * 2.0 - 1.0;
    float nz = sqrt(max(0.0, 1.0 - nxy.x*nxy.x - nxy.y*nxy.y));
    vec3 n = normalize(vec3(nxy, nz));

    float height = depthMapPixel.b;
    vec4 albedoPixel = texture(albedoMap, uv);

    vec3 fragPos = vec3(uv, height);
    vec3 L = vec3(lightPos, 1.0) - fragPos;
    float dist = length(L);
    L = normalize(L);

    float NdotL = max(dot(n, L), 0.0);

    float range = 4.2;
    float att = 1.0 / (1.0 + 16.0 * (dist / range) * (dist / range));

    vec3 lightColor = vec3(0.2, 0.3, 1.0);
    vec3 diffuse = lightColor * NdotL * att;

    vec3 ambient = vec3(0.4, 0.36, 0.32);

    vec3 color = albedoPixel.rgb * (ambient + diffuse);

    fragColor = vec4(color, albedoPixel.a);
}
