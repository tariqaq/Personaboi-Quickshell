#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float PERSONABOI_INTENSITY = 1.000;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    vec3 inverted = 1.0 - pixColor.rgb;
    fragColor = vec4(mix(pixColor.rgb, inverted, PERSONABOI_INTENSITY), pixColor.a);
}
