precision mediump float;

out vec4 fragColor;

uniform vec2 uSize;

void main() {
    vec2 uv = gl_FragCoord.xy / uSize;

    fragColor = vec4(uv.x, uv.y, 0.5, 0.1);
}