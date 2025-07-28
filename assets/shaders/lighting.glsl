precision mediump float;

out vec4 fragColor;

uniform vec2 uSize;
uniform vec2 uPlayerPos;
uniform vec2 uLightPos;
uniform float uTime;

uniform float uObjectCount;
uniform vec4 uObject0;
uniform vec4 uObject1;
uniform vec4 uObject2;
uniform vec4 uObject3;
uniform vec4 uObject4;

vec4 getObject(int index) {
    if(index == 0) return uObject0;
    if(index == 1) return uObject1;
    if(index == 2) return uObject2;
    if(index == 3) return uObject3;
    if(index == 4) return uObject4;
    return vec4(0.0);
}

bool isInsideRect(vec2 point, vec4 rect) {
    vec2 halfSize = rect.zw * 0.5;
    vec2 min = rect.xy - halfSize;
    vec2 max = rect.xy + halfSize;
    return all(greaterThanEqual(point, min)) && all(lessThanEqual(point, max));
}


bool isInShadow(vec2 point, vec2 light) {
    vec2 dir = normalize(light - point);
    float totalDist = length(light - point);

    int objCount = int(uObjectCount);

    for (int i = 0; i < 5; i++) {
        if (i >= objCount) break;

        vec4 obj = getObject(i);

        for (float t = 0.05; t < 1.0; t += 0.05) {
            vec2 testPoint = mix(point, light, t);
            if (isInsideRect(testPoint, obj)) {
                return true;
            }
        }
    }

    return false;
}

void main() {
    vec2 uv = gl_FragCoord.xy / uSize;

    float distToLight = length(uLightPos - uv);
    float lightIntensity = 1.0 / (1.0 + distToLight * distToLight * 3.0);

    bool inShadow = isInShadow(uv, uLightPos);
    if (inShadow) {
        lightIntensity *= 0.2;
    }

    float distToPlayer = length(uPlayerPos - uv);
    float playerGlow = 0.0;
    if (distToPlayer < 0.1) {
        playerGlow = (1.0 - distToPlayer / 0.1) * 0.3;
    }

    float totalLight = 0.1 + lightIntensity + playerGlow;
    vec3 lightColor = vec3(1.0, 0.9, 0.7);
    vec3 finalColor = lightColor * totalLight;

    float lightDebug = smoothstep(0.02, 0.0, length(uv - uLightPos));
    finalColor += vec3(lightDebug, 0.0, 0.0);


    float lightMark = smoothstep(0.02, 0.0, length(uv - uLightPos));
    float playerMark = smoothstep(0.02, 0.0, length(uv - uPlayerPos));



    fragColor = vec4(finalColor, 1.0);
    fragColor.rgb += vec3(lightMark, 0.0, 0.0);
    fragColor.rgb += vec3(0.0, playerMark, 0.0);
}
