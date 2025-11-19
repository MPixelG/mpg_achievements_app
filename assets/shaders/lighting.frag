precision mediump float;
#include <flutter/runtime_effect.glsl>

uniform sampler2D albedoMap;
uniform sampler2D depthMap;
uniform vec2 screenSize;
uniform vec3 lightPos;
uniform float heightScale;
uniform float testUniform;

out vec4 fragColor;

vec2 iso2orth(vec3 iso) {
    float sum = iso.y / heightScale + iso.z;
    float diff = iso.x;
    float x = (sum + diff) * 0.5;
    float y = (sum - diff) * 0.5;
    return vec2(x, y);
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
    vec3 adjustedLightPos = lightPos;
    vec2 uv = (FlutterFragCoord().xy) / screenSize;
    vec4 albedoPixel = texture(albedoMap, uv);
    vec4 normalPixel = texture(depthMap, uv);

    if(normalPixel.a == 0) return;


    float pixelHeight = normalPixel.b;

    float dx = (1.0 / screenSize.x) * 1;
    float dy = (1.0 / screenSize.y) * 1;
    float H = texture(depthMap, uv).b;

    float Hleft  = texture(depthMap, uv + vec2(-dx, 0.0)).b;
    float Hright = texture(depthMap, uv + vec2(+dx, 0.0)).b;
    float Hdown  = texture(depthMap, uv + vec2(0.0, -dy)).b;
    float Hup    = texture(depthMap, uv + vec2(0.0, +dy)).b;

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

    float HleftUp  = texture(depthMap, uv + vec2(-dx, -dy)).b;

    //if(pixelHeight - Hleft < -0.01 || pixelHeight - Hup < -0.01) color.rgb *= 0.8;

    fragColor = vec4(color, albedoPixel.a);
}