#language slang 2026
// SPDX-License-Identifier: MIT
import kitty_custom_shader_types;

// Detect input panels drawn between two long horizontal rules near the bottom of the pane.
// Claude-style panels rule their input in neutral gray; themed TUIs such as pi draw the same
// rule pair in their own border color, so a tinted pair whose rules share one color counts too.
// This pass renders only a narrow scratch column, rather than scanning per pixel.
static const bool DETECT_RULED_PANELS = true;
static const bool DETECT_TINTED_RULES = true;
static const int SEARCH_PIXELS = 192;
static const float BOTTOM_PIXELS = 320.0;

// A rule spans the panel width, so its row is one flat color at every sampled column.
bool uniform_row(float y, KittyTextures t, float4 pane, out float3 color) {
    color = float3(0.0);
    if (y <= pane.y || y >= pane.y + pane.w) return false;
    float3 a = t.backbuffer.Sample(float2(pane.x + pane.z * 0.35, y)).rgb;
    float3 b = t.backbuffer.Sample(float2(pane.x + pane.z * 0.65, y)).rgb;
    float3 c = t.backbuffer.Sample(float2(pane.x + pane.z * 0.90, y)).rgb;
    color = a;
    return all(abs(a - b) < float3(0.005)) && all(abs(a - c) < float3(0.005));
}

// The colorless, mid-tone rules of a Claude-style panel.
bool neutral_rule(float3 color) {
    return color.r > 0.06 && color.r < 0.65 && abs(color.r - color.g) < 0.005 && abs(color.g - color.b) < 0.005;
}

// A rule drawn in a themed border color: still dimmer than text, but tinted rather than gray.
bool tinted_rule(float3 color) {
    return all(color > float3(0.02)) && all(color < float3(0.8));
}

// The window background itself never rules a panel, whatever its brightness.
bool background_row(float3 color, float3 background) {
    return all(abs(color - background) < float3(0.002));
}

// Pixels from this row to the nearest matching rule above (direction 1) or below (direction -1).
int nearest_rule(float y, float height, KittyTextures t, float4 pane, float3 background, float direction, bool tinted, out float3 color) {
    color = float3(0.0);
    for (int offset = 1; offset <= SEARCH_PIXELS; offset++) {
        float3 found;
        if (!uniform_row(y + direction * float(offset) / height, t, pane, found)) continue;
        if (!background_row(found, background) && (tinted ? tinted_rule(found) : neutral_rule(found))) {
            color = found;
            return offset;
        }
    }
    return 0;
}

public float4 fragment_main(float4 color, KittyTextures t, KittyCustomShaderData d) {
    float4 pane = d.active_window_geometry;
    float y = t.pos.y;
    float height = float(d.viewport_size_pixels.y);
    if (!DETECT_RULED_PANELS || pane.z <= 0 || pane.w <= 0 || y <= pane.y || y >= pane.y + pane.w
        || (y - pane.y) * height > BOTTOM_PIXELS) return float4(0, 0, 0, 1);

    float3 self = float3(0.0);
    float3 background = d.active_window_background.rgb;
    bool self_is_rule = uniform_row(y, t, pane, self) && !background_row(self, background)
        && (neutral_rule(self) || (DETECT_TINTED_RULES && tinted_rule(self)));
    if (self_is_rule) return float4(0, 0, 0, 1);

    float3 above_color = float3(0.0);
    float3 below_color = float3(0.0);
    int above = nearest_rule(y, height, t, pane, background, 1.0, false, above_color);
    int below = nearest_rule(y, height, t, pane, background, -1.0, false, below_color);
    bool panel = above > 0 && below > 0 && above + below >= 12 && above + below <= SEARCH_PIXELS;
    bool edge = panel && min(above, below) <= 2;

    // A themed panel rules its top and bottom with one color, so unmatched rules nearby do not pair.
    if (!panel && DETECT_TINTED_RULES) {
        above = nearest_rule(y, height, t, pane, background, 1.0, true, above_color);
        below = nearest_rule(y, height, t, pane, background, -1.0, true, below_color);
        panel = above > 0 && below > 0 && all(abs(above_color - below_color) < float3(0.02))
            && above + below >= 12 && above + below <= SEARCH_PIXELS;
        if (panel) edge = min(above, below) <= 2;
    }
    return float4(panel ? 1.0 : 0.0, edge ? 1.0 : 0.0, 0, 1);
}
