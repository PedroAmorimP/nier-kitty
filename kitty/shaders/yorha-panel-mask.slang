#language slang 2026
// SPDX-License-Identifier: MIT
import kitty_custom_shader_types;

// Detect Claude-style input panels between two long neutral horizontal rules.
// This pass renders only a narrow scratch column, rather than scanning per pixel.
static const bool DETECT_RULED_PANELS = true;
static const int SEARCH_PIXELS = 192;
static const float BOTTOM_PIXELS = 320.0;

bool rule_at(float y, KittyTextures t, float4 pane) {
    if (y <= pane.y || y >= pane.y + pane.w) return false;
    float3 a = t.backbuffer.Sample(float2(pane.x + pane.z * 0.35, y)).rgb;
    float3 b = t.backbuffer.Sample(float2(pane.x + pane.z * 0.65, y)).rgb;
    float3 c = t.backbuffer.Sample(float2(pane.x + pane.z * 0.90, y)).rgb;
    return a.r > 0.06 && a.r < 0.65 && abs(a.r - a.g) < 0.005 && abs(a.g - a.b) < 0.005
        && all(abs(a - b) < float3(0.005)) && all(abs(a - c) < float3(0.005));
}

public float4 fragment_main(float4 color, KittyTextures t, KittyCustomShaderData d) {
    float4 pane = d.active_window_geometry;
    float y = t.pos.y;
    float height = float(d.viewport_size_pixels.y);
    if (!DETECT_RULED_PANELS || pane.z <= 0 || pane.w <= 0 || y <= pane.y || y >= pane.y + pane.w
        || (y - pane.y) * height > BOTTOM_PIXELS || rule_at(y, t, pane)) return float4(0, 0, 0, 1);

    int above = 0;
    int below = 0;
    for (int offset = 1; offset <= SEARCH_PIXELS; offset++) {
        float dy = float(offset) / height;
        if (above == 0 && rule_at(y + dy, t, pane)) above = offset;
        if (below == 0 && rule_at(y - dy, t, pane)) below = offset;
        if (above > 0 && below > 0) break;
    }
    bool panel = above > 0 && below > 0 && above + below >= 12 && above + below <= SEARCH_PIXELS;
    return float4(panel ? 1.0 : 0.0, panel && min(above, below) <= 2 ? 1.0 : 0.0, 0, 1);
}
