#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform sampler2D textureSampler;
uniform sampler2D normalSampler;

uniform vec2 lightPos;
uniform vec2 tilePos;
uniform vec2 uResolution;
uniform float tileZ;

out vec4 fragColor;

mat3 getIsometricNormalTransform() {
    float angle = radians(45.0);
    float cosA = cos(angle);
    float sinA = sin(angle);

    return mat3(
    cosA, 0.0, sinA,
    0.0, 1.0, 0.0,
    -sinA, 0.0, cosA
    );
}

void main() {
    vec2 fragPx = FlutterFragCoord().xy - tilePos;
    vec2 uv = fragPx / uResolution;

    vec3 normal = texture(normalSampler, uv).rgb * 2.0 - 1.0;

    mat3 isoTransform = getIsometricNormalTransform();
    normal = normalize(isoTransform * normal);

    vec2 worldFragPos = FlutterFragCoord().xy;
    vec3 fragPos3D = vec3(worldFragPos, tileZ);

    vec3 lightPos3D = vec3(lightPos, 100.0);

    vec3 lightDir = normalize(lightPos3D - fragPos3D);

    float diff = max(dot(normal, lightDir)*1.6, 0.8);

    vec4 textureColor = texture(textureSampler, uv);
    vec3 globalLightColor = normalize(vec3(0.29, 0.26, 0.23));

    fragColor = vec4(textureColor.rgb * diff * globalLightColor, textureColor.a);
}