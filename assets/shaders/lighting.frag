precision mediump float;
#include <flutter/runtime_effect.glsl>

uniform sampler2D albedoMap;
uniform sampler2D depthMap;
uniform vec2 screenSize;
uniform vec3 lightPos;
uniform float heightScale;

out vec4 fragColor;

vec2 iso2orth(vec3 iso) {
    float sum = iso.y / heightScale + iso.z;
    float diff = iso.x;
    float x = (sum + diff) * 0.5;
    float y = (sum - diff) * 0.5;
    return vec2(x, y);
}


vec3 calculateBasicLighting(){
    vec2 uv = FlutterFragCoord().xy / screenSize;


    vec4 depthMapPixel = texture(depthMap, uv);
    vec2 nxy = depthMapPixel.rg * 2.0 - 1.0;
    float nz = sqrt(max(0.0, 1.0 - nxy.x*nxy.x - nxy.y*nxy.y));
    vec3 n = normalize(vec3(nxy, nz));

    float height = depthMapPixel.b;

    vec3 fragPos = vec3(uv, height);

    vec3 L = lightPos - fragPos;
    float dist = length(L);
    L = normalize(L);

    float NdotL = max(dot(n, L), 0);
    float range = 20.2;
    float att = 1.0 / (1.0 + 16.0 * (dist / range) * (dist / range));

    vec3 lightColor = vec3(0, 0.2, 1);
    vec3 diffuse = lightColor * NdotL * att * 3;

    return diffuse;
}

float calculateShadow(vec3 fragPos, vec3 dirToLight, float heightScale){
    vec3 currentPos = fragPos;
    float stepSize = 0.005;

    float shadow = 1.0;

    for (int i = 0; i < 5; i++){
        currentPos += dirToLight * stepSize;

        if (any(lessThan(currentPos.xy, vec2(0.0))) || any(greaterThan(currentPos.xy, vec2(1.0)))){
            break;
        }

        float heightVal = texture(depthMap, currentPos.xy).b * heightScale;

        if (heightVal > currentPos.z + 0.1){
            shadow = clamp(shadow - 0.9, 0.0, 1.0);
            break;
        }
    }
    return shadow;
}
void main() {
    vec2 uv = FlutterFragCoord().xy / screenSize;
    vec4 albedoPixel = texture(albedoMap, uv);
    float pixelHeight = texture(depthMap, uv).b;

    float heightScale = 0.5;
    vec3 fragPos = vec3(uv, pixelHeight * heightScale);
    vec3 dirToLight = normalize(lightPos - fragPos);


    //vec3 diffuse = calculateBasicLighting();
//    float shadow = calculateShadow(fragPos, dirToLight, heightScale);
    vec3 color = albedoPixel.rgb * (vec3(0.15, 0.1, 0.3));

    fragColor = vec4(color, albedoPixel.a);
}