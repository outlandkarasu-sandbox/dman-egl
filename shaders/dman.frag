varying mediump vec4 vertexColor;
varying mediump vec2 vertexUv;

uniform sampler2D textureSampler;

void main() {
    gl_FragColor = vec4(texture2D(textureSampler, vertexUv).rgb, 1.0);
}
