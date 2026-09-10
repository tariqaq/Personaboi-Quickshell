//
// Persona blue light filter with runtime-adjustable intensity.
// Scripts/apply-shader.sh rewrites only the constant below in a cache copy.
//

#version 300 es

precision mediump float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

const float PERSONABOI_INTENSITY = 1.000;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    vec3 filtered = pixColor.rgb;
    filtered.b *= 0.8;
    fragColor = vec4(mix(pixColor.rgb, filtered, PERSONABOI_INTENSITY), pixColor.a);
}
