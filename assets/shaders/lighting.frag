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
uniform float time;

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


// GLSL Perlin Noise (2D + 3D)
// Author: minimal, well-behaved implementation

// Hash / permutation (returns value in [0,1])
float perm(float x) {
    return fract(sin(x) * 43758.5453123);
}
vec3 perm(vec3 x) {
    return fract(sin(x) * 43758.5453123);
}

// Fade curve (6t^5 - 15t^4 + 10t^3)
float fade(float t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}
vec2 fade(vec2 t) { return vec2(fade(t.x), fade(t.y)); }
vec3 fade(vec3 t) { return vec3(fade(t.x), fade(t.y), fade(t.z)); }

// Gradient for 2D: returns a unit vector from a hash
vec2 grad2(float hash) {
    float angle = hash * 6.28318530718; // 2*pi
    return vec2(cos(angle), sin(angle));
}

// 2D Perlin noise
float perlin2(vec2 P) {
    // Grid cell
    vec2 Pi = floor(P);
    vec2 Pf = P - Pi;

    // Wrap indices (optional) -> keep large numbers stable
    Pi = mod(Pi, 289.0);

    // Hash the corners
    float h00 = perm(Pi.x + perm(Pi.y));
    float h10 = perm(Pi.x + 1.0 + perm(Pi.y));
    float h01 = perm(Pi.x + perm(Pi.y + 1.0));
    float h11 = perm(Pi.x + 1.0 + perm(Pi.y + 1.0));

    // Gradients
    vec2 g00 = grad2(h00);
    vec2 g10 = grad2(h10);
    vec2 g01 = grad2(h01);
    vec2 g11 = grad2(h11);

    // Offsets
    vec2 d00 = Pf - vec2(0.0, 0.0);
    vec2 d10 = Pf - vec2(1.0, 0.0);
    vec2 d01 = Pf - vec2(0.0, 1.0);
    vec2 d11 = Pf - vec2(1.0, 1.0);

    // Dot products
    float n00 = dot(g00, d00);
    float n10 = dot(g10, d10);
    float n01 = dot(g01, d01);
    float n11 = dot(g11, d11);

    // Interpolate
    vec2 u = fade(Pf);
    float nx0 = mix(n00, n10, u.x);
    float nx1 = mix(n01, n11, u.x);
    float nxy = mix(nx0, nx1, u.y);

    // Normalize result to [-1,1] approx
    return clamp(nxy * 1.41421356, -1.0, 1.0);
}

vec3 gradVec(int i) {
    if (i == 0)  return vec3( 1.0,  1.0,  0.0);
    if (i == 1)  return vec3(-1.0,  1.0,  0.0);
    if (i == 2)  return vec3( 1.0, -1.0,  0.0);
    if (i == 3)  return vec3(-1.0, -1.0,  0.0);
    if (i == 4)  return vec3( 1.0,  0.0,  1.0);
    if (i == 5)  return vec3(-1.0,  0.0,  1.0);
    if (i == 6)  return vec3( 1.0,  0.0, -1.0);
    if (i == 7)  return vec3(-1.0,  0.0, -1.0);
    if (i == 8)  return vec3( 0.0,  1.0,  1.0);
    if (i == 9)  return vec3( 0.0, -1.0,  1.0);
    if (i == 10) return vec3( 0.0,  1.0, -1.0);
    return vec3(0.0, -1.0, -1.0);
}

vec3 grad3(float hash)
{
    float h = floor(hash * 12.0);
    int ih = int(mod(h, 12.0));
    return normalize( gradVec(ih) );
}

float perlin3(vec3 P) {
    vec3 Pi = floor(P);
    vec3 Pf = P - Pi;
    Pi = mod(Pi, 289.0);

    // Hash corners
    float A  = perm(Pi.x + perm(Pi.y + perm(Pi.z)));
    float A1 = perm(Pi.x + 1.0 + perm(Pi.y + perm(Pi.z)));
    float B  = perm(Pi.x + perm(Pi.y + 1.0 + perm(Pi.z)));
    float B1 = perm(Pi.x + 1.0 + perm(Pi.y + 1.0 + perm(Pi.z)));
    float C  = perm(Pi.x + perm(Pi.y + perm(Pi.z + 1.0)));
    float C1 = perm(Pi.x + 1.0 + perm(Pi.y + perm(Pi.z + 1.0)));
    float D  = perm(Pi.x + perm(Pi.y + 1.0 + perm(Pi.z + 1.0)));
    float D1 = perm(Pi.x + 1.0 + perm(Pi.y + 1.0 + perm(Pi.z + 1.0)));

    // Gradients
    vec3 g000 = grad3(A);
    vec3 g100 = grad3(A1);
    vec3 g010 = grad3(B);
    vec3 g110 = grad3(B1);
    vec3 g001 = grad3(C);
    vec3 g101 = grad3(C1);
    vec3 g011 = grad3(D);
    vec3 g111 = grad3(D1);

    // Offsets
    vec3 d000 = Pf - vec3(0.0,0.0,0.0);
    vec3 d100 = Pf - vec3(1.0,0.0,0.0);
    vec3 d010 = Pf - vec3(0.0,1.0,0.0);
    vec3 d110 = Pf - vec3(1.0,1.0,0.0);
    vec3 d001 = Pf - vec3(0.0,0.0,1.0);
    vec3 d101 = Pf - vec3(1.0,0.0,1.0);
    vec3 d011 = Pf - vec3(0.0,1.0,1.0);
    vec3 d111 = Pf - vec3(1.0,1.0,1.0);

    // Dot products
    float n000 = dot(g000, d000);
    float n100 = dot(g100, d100);
    float n010 = dot(g010, d010);
    float n110 = dot(g110, d110);
    float n001 = dot(g001, d001);
    float n101 = dot(g101, d101);
    float n011 = dot(g011, d011);
    float n111 = dot(g111, d111);

    // Interpolate
    vec3 u = fade(Pf);
    float nx00 = mix(n000, n100, u.x);
    float nx01 = mix(n001, n101, u.x);
    float nx10 = mix(n010, n110, u.x);
    float nx11 = mix(n011, n111, u.x);

    float nxy0 = mix(nx00, nx10, u.y);
    float nxy1 = mix(nx01, nx11, u.y);

    float nxyz = mix(nxy0, nxy1, u.z);

    // Normalize approx
    return clamp(nxyz * 1.7320508, -1.0, 1.0);
}

float perlin3Octaves(vec3 P){

    // Parameters
    const int OCTAVES = 15;
    const float LACUNARITY = 2.2;   // frequency multiplier per octave
    const float GAIN = 0.5;         // amplitude multiplier per octave

    float amplitude = 1.0;
    float frequency = 1.0;
    float result = 0.0;
    float totalAmp = 0.0;

    // use time as small offset to animate without breaking integer grid alignment
    vec3 timeOffset = vec3(time * 0.0003, time * 0.0003, time * 0.000125);

    for(int i = 0; i < OCTAVES; i++){
        result += perlin3(P * frequency) * amplitude;
        totalAmp += amplitude;
        frequency *= LACUNARITY;
        amplitude *= GAIN;
    }

    // normalize to [-1,1] range approximately
    return pow(abs(clamp(-0.2, 1, result / totalAmp))*2.5, 8);
}

float lerp(float min, float max, float x){
    return x*(max-min)+min;
}
// --- Robust projected shadow (screen-space raymarch) ---
float getHeightAtScreen(vec2 screen) {
    vec2 uv = screen / mapSize;
    vec2 uvEntity = (screen + entityMapOffset) / entityMapSize;
    float hTerrain = texture(depthMap, uv).b;
    float hEntity  = texture(depthMapEntity, uvEntity).b;
    return max(hTerrain, hEntity);
}

float computeProjectedShadow(vec2 uv, vec2 uvEntity, vec2 fragScreen, vec3 lightPos) {
    // STEPS / quality
    const int STEPS = 64;
    float eps = 0.001;

    // Light in screen space (pixel coords)
    vec2 lightScreen = lightPos.xy * mapSize;

    // if light very close to fragment -> lit
    float totalDist = length(lightScreen - fragScreen);
    if (totalDist < 1.0) return 1.0;

    // convert heights to same scaled units (apply heightScale)
    float fragH = getHeightAtScreen(fragScreen) * heightScale;
    float lightH = lightPos.z * heightScale;

    // step vector in screen space
    vec2 step = (lightScreen - fragScreen) / float(STEPS);

    float shadow = 1.0;
    // march from fragment towards light (skip i=0)
    for (int i = 1; i <= STEPS; ++i) {
        vec2 sampleScreen = fragScreen + step * float(i);
        float t = float(i) / float(STEPS); // normalized position along ray

        // expected ray height at this sample
        float rayH = mix(fragH, lightH, t);

        // actual height from maps (also scaled)
        float sampleH = getHeightAtScreen(sampleScreen) * heightScale;

        // occlusion check with small bias
        if (sampleH > rayH + eps) {
            // soft edge: stronger occluder (higher delta) => darker shadow
            float occlusion = clamp((sampleH - (rayH + eps)) / (0.02 * heightScale), 0.0, 1.0);
            // penumbra approx: near the fragment -> sharper, far -> softer
            float penumbra = smoothstep(0.0, 1.0, t);
            float localShadow = mix(0.25, 0.6, penumbra); // min ambient in shadow
            // combine: stronger occlusion reduces intensity more
            shadow = min(shadow, mix(1.0, localShadow, occlusion));
            // optionally break early for perf (but breaking loses softer penumbra)
            // break;
        }
    }

    return clamp(shadow, 0.0, 1.0);
}




void main() {
    vec2 uv = (FlutterFragCoord().xy) / mapSize;
    vec2 uvEntity = (FlutterFragCoord().xy + entityMapOffset) / entityMapSize;
    vec4 albedoPixel = texture(albedoMap, uv);
    vec4 albedoPixelEntity = texture(albedoMapEntity, uvEntity);
    vec4 normalPixel = texture(depthMap, uv);
    vec4 normalPixelEntity = texture(depthMapEntity, uvEntity);
    float pixelHeight = normalPixel.b;
    float pixelHeightEntity = normalPixelEntity.b;


    //if(normalPixel.a == 0 && normalPixelEntity.a == 0) return;

    if(pixelHeightEntity > pixelHeight){
        albedoPixel = albedoPixelEntity + (albedoPixel.a-albedoPixelEntity.a)*albedoPixel;
        normalPixel = normalPixelEntity + (normalPixel.a-normalPixelEntity.a)*normalPixel;
        pixelHeight = pixelHeightEntity + (albedoPixel.a-albedoPixelEntity.a)*pixelHeight;
    } else {
        albedoPixel += albedoPixelEntity * 0.8; // slight glow from entities, even when behind walls
    }


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


    //if(pixelHeight - Hleft < -0.01 || pixelHeight - Hup < -0.01) color.rgb *= 0.8;
    //float scale = 3;
    //float cloudVal = lerp(0.6, 0.9, perlin3Octaves(vec3(uv.x/scale + (time / 22000), uv.y/scale + (time / 22000), time / 30000)));

    vec3 lightColor = vec3(1, 0.7, 0.75);

    //vec2 fragScreen = FlutterFragCoord().xy;
    //float shadowFactor = computeProjectedShadow(uv, uvEntity, fragScreen, lightPos);

    vec3 diffuse = lightColor * NdotL * (((pixelHeight) / 5) + 0.75);

    vec3 color = albedoPixel.rgb * (vec3(0.11, 0.1, 0.1)*2 + diffuse);

    fragColor = vec4(color, albedoPixel.a);
}