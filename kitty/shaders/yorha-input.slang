#language slang 2026
// SPDX-License-Identifier: MIT
// YoRHa input shimmer. Colors are linear RGB, matching Kitty's backbuffer.
import kitty_custom_shader_types;

// Input background measured from the reference: sRGB #302d2a.
// Change INPUT_RGB if the application's input background changes.
static const float3 INPUT_RGB = float3(48.0, 45.0, 42.0) / 255.0;
static const float INTENSITY = 0.6;
static const float SPEED = 1.0;
static const float PARTICLE_DENSITY = 0.28;
static const float SPARKLE_BRIGHTNESS = 0.12;

float3 linear_rgb(float3 rgb) {
    return pow((rgb + 0.055) / 1.055, float3(2.4));
}

float hash(float n) {
    return frac(sin(n * 127.1 + 311.7) * 43758.5453);
}

bool input_pixel(float4 pixel) {
    // A narrow color match leaves text, the cursor, selections and ANSI colors alone.
    return pixel.a > 0.99 && all(abs(pixel.rgb - linear_rgb(INPUT_RGB)) < float3(0.0007));
}

public float4 fragment_main(float4 color, KittyTextures t, KittyCustomShaderData d) {
    float4 pane = d.active_window_geometry;
    float2 uv = t.pos;
    if (pane.z <= 0 || pane.w <= 0 || any(uv < pane.xy) || any(uv > pane.xy + pane.zw)) return color;
    bool colored_panel = input_pixel(color);
    float2 panel_mask = t.a.Sample(float2(0.005, uv.y)).rg;
    bool ruled_panel = panel_mask.r > 0.5 && color.a > 0.99
        && all(abs(color.rgb - d.active_window_background.rgb) < float3(0.0007));
    if (!colored_panel && !ruled_panel) return color;

    float2 size = float2(d.viewport_size_pixels);
    float2 p = (uv - pane.xy) * size;
    float width = max(pane.z * size.x, 1.0);
    float time = fmod(d.timestamp, 3600.0) * SPEED;
    float x = p.x / width;
    float3 bronze = linear_rgb(float3(41.0, 34.0, 24.0) / 255.0);
    float3 amber = linear_rgb(float3(232.0, 185.0, 104.0) / 255.0);
    float3 paper = linear_rgb(float3(242.0, 228.0, 188.0) / 255.0);

    // Wide soft light travels back and forth in a fourteen-second cycle.
    float center = 0.5 + 0.38 * sin(time * 0.2244);
    float wave = exp(-pow((x - center) / 0.25, 2.0));
    float sheen = exp(-pow((x - center - 0.14) / 0.075, 2.0));
    float scan = 0.5 + 0.5 * cos(p.y * 1.5707963);
    float3 effect = amber * (0.018 * wave + 0.012 * sheen + 0.001 * scan);

    // Sparse particles: evaluate nearby tiles so drifting points cross seams smoothly.
    float2 moving = p - float2(time * 2.0, time * 0.45);
    float2 tile = floor(moving / float2(96.0, 28.0));
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            float2 cell = tile + float2(i, j);
            float seed = cell.x * 17.0 + cell.y * 131.0;
            if (hash(seed) > PARTICLE_DENSITY) continue;
            float2 point = (cell + float2(hash(seed + 1.0), hash(seed + 2.0))) * float2(96.0, 28.0);
            float2 delta = abs(moving - point);
            float shape = hash(seed + 3.0) > 0.8 ? delta.x + delta.y : length(delta);
            float spark = 1.0 - smoothstep(0.4, 1.8, shape);
            float halo = exp(-dot(delta, delta) / 10.0) * 0.12;
            float twinkle = pow(0.5 + 0.5 * sin(time * 0.65 + hash(seed + 4.0) * 6.2831853), 2.0);
            effect += paper * (spark + halo) * twinkle * SPARKLE_BRIGHTNESS;
        }
    }

    // Detect the strip's horizontal edges away from its text column.
    float2 probe = float2(pane.x + pane.z * 0.85, uv.y);
    float2 dy = float2(0.0, 1.0 / size.y);
    if (ruled_panel && panel_mask.g > 0.5) effect += amber * (0.03 + 0.05 * sheen);
    if (colored_panel && input_pixel(t.backbuffer.Sample(probe))) {
        bool edge = !input_pixel(t.backbuffer.Sample(probe + dy)) || !input_pixel(t.backbuffer.Sample(probe - dy));
        if (edge) effect += amber * (0.03 + 0.05 * sheen);
    }
    return float4(bronze + effect * INTENSITY, color.a);
}
