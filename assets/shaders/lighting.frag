precision mediump float;
#include <flutter/runtime_effect.glsl>

uniform sampler2D albedoMap;
uniform sampler2D depthMap;
uniform sampler2D albedoMapEntity;
uniform sampler2D depthMapEntity;
uniform vec2 mapSize;
uniform vec2 entityMapSize;
uniform vec2 entityMapOffset;
uniform vec3 lightPos;
uniform float heightScale;
uniform float testUniform;

out vec4 fragColor;

float dx = (1.0 / mapSize.x) * 1;
float dy = (1.0 / mapSize.y) * 1;
float dxEntity = (1.0 / entityMapSize.x) * 1;
float dyEntity = (1.0 / entityMapSize.y) * 1;

float heightInDirection(vec2 uv, vec2 uvEntity, vec2 dir) {
    float h = texture(depthMap, uv).b;
    float hEntity = texture(depthMapEntity, uvEntity).b;
    if(hEntity > h){
        return texture(depthMapEntity, uvEntity + dir*vec2(dxEntity, dyEntity)).b;
    }

    return texture(depthMap, uv + dir*vec2(dx, dy)).b;
}

void main() {
    vec3 adjustedLightPos = lightPos;

    vec2 uv = (FlutterFragCoord().xy) / mapSize;
    vec2 uvEntity = (FlutterFragCoord().xy + entityMapOffset) / entityMapSize;

    vec4 albedoPixel = texture(albedoMap, uv);
    vec4 albedoPixelEntity = texture(albedoMapEntity, uvEntity);

    albedoPixel += albedoPixelEntity / 7; // slight glow from entities, even when behind walls


    vec4 normalPixel = texture(depthMap, uv);
    vec4 normalPixelEntity = texture(depthMapEntity, uvEntity);

    if(normalPixel.a == 0 && normalPixelEntity.a == 0) return;


    float pixelHeight = normalPixel.b;
    float pixelHeightEntity = normalPixelEntity.b;

    if(pixelHeightEntity > pixelHeight){
        albedoPixel = albedoPixelEntity + (albedoPixel.a-albedoPixelEntity.a)*albedoPixel;
        normalPixel = normalPixelEntity;
        pixelHeight = pixelHeightEntity;
    }

//    fragColor = normalPixel;
//    return;


    float Hleft  = heightInDirection(uv, uvEntity, vec2(-1.0, 0.0));
    float Hright = heightInDirection(uv, uvEntity, vec2(+1.0, 0.0));
    float Hdown  = heightInDirection(uv, uvEntity, vec2(+0.0, -1.0));
    float Hup    = heightInDirection(uv, uvEntity, vec2(+0.0, +1.0));

    float dHx = Hright - Hleft;
    float dHy = Hup - Hdown;

    float normalStrength = 0.06;

    vec3 normal = normalize(vec3(-dHx, -dHy, normalStrength));

    normalPixel.rgb = normal * 0.5 + 0.5;


    vec3 fragPos = vec3(uv, pixelHeight);
    vec3 L = lightPos - fragPos;
    float dist = length(L);
    L = normalize(L);

    float NdotL = max(dot(normalPixel.rgb, L), 0);
    float range = 2.2;
    float att = 1.0 / (1.0 + 16.0 * (dist / range) * (dist / range));

    vec3 lightColor = vec3(1, 0.7, 0.75);
    vec3 diffuse = lightColor * NdotL  * (((pixelHeight) / 5) + 0.75);
    vec3 color = albedoPixel.rgb * (vec3(0.11, 0.1, 0.1)*2 + diffuse);

    float HleftUp  = heightInDirection(uv, uvEntity, vec2(-1.0, +1.0));

    //if(pixelHeight - Hleft < -0.01 || pixelHeight - Hup < -0.01) color.rgb *= 0.8;

    fragColor = vec4(color, albedoPixel.a);
}