#!/usr/bin/env bash
set -euo pipefail

if ! command -v hyprctl >/dev/null 2>&1; then
    exit 1
fi

shader_path="${1:-}"
intensity="${2:-1.0}"

if [[ "$shader_path" == "off" || -z "$shader_path" ]]; then
    hyprctl keyword decoration:screen_shader '[[EMPTY]]' >/dev/null
    exit 0
fi

if [[ ! -r "$shader_path" ]]; then
    exit 1
fi

# Clamp to 0..1 and render a per-user runtime copy. Hyprland exposes a shader
# path at runtime, not arbitrary custom uniforms, so the intensity constant is
# baked into the temporary shader before switching to it.
intensity="$(awk -v value="$intensity" 'BEGIN {
    v = value + 0;
    if (v < 0) v = 0;
    if (v > 1) v = 1;
    printf "%.3f", v;
}')"

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/personaboi/shaders"
mkdir -p "$cache_dir"
runtime_shader="$cache_dir/active.glsl"

awk -v intensity="$intensity" '
    /^const float PERSONABOI_INTENSITY = / {
        print "const float PERSONABOI_INTENSITY = " intensity ";"
        next
    }
    { print }
' "$shader_path" > "$runtime_shader.tmp"
mv "$runtime_shader.tmp" "$runtime_shader"

hyprctl keyword decoration:screen_shader "$runtime_shader" >/dev/null
