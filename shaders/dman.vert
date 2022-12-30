attribute mediump vec3 position;
attribute mediump vec4 color;
attribute mediump vec2 uv;

uniform mediump mat4 transform;

varying mediump vec4 vertexColor;
varying mediump vec2 vertexUv;

void main() {
    gl_Position = transform * vec4(position, 1.0);
    vertexColor = color;
    vertexUv = uv;
}
