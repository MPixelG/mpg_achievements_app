precision mediump float;

uniform sampler2D uTexture1;
uniform sampler2D uTexture2;
uniform vec2 uResolution;

out vec4 fragColor;

void main() {
    vec2 uv = gl_FragCoord.xy / uResolution;

    vec4 colorA = texture(uTexture1, uv);
    vec4 colorB = texture(uTexture2, uv);

    vec4 result = vec4(
    colorA.r * (1.0 - colorB.r) + colorB.r,
    colorA.g * (1.0 - colorB.g) + colorB.g,
    colorA.b * (1.0 - colorB.b) + colorB.b,
    1.0
    );

    fragColor = result;
}