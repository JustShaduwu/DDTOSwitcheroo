#pragma header

uniform float radius;
uniform float strength;

vec4 sampleText(vec2 uv)
{
    if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) return vec4(0.0);
    return flixel_texture2D(bitmap, uv);
}

void main()
{
    vec2 uv = openfl_TextureCoordv.xy;
    vec2 pixel = vec2(max(radius, 0.5)) / openfl_TextureSize;
    vec4 original = sampleText(uv);
    vec3 blurred = vec3(0.0);
    float weightSum = 0.0;
    // Full camera texture gives the halo room beyond each glyph and text bounds.
    for (int y = -3; y <= 3; y++)
    {
        for (int x = -3; x <= 3; x++)
        {
            vec2 offset = vec2(float(x), float(y));
            float weight = exp(-dot(offset, offset) / 4.5);
            blurred += sampleText(uv + offset * pixel).rgb * weight;
            weightSum += weight;
        }
    }
    vec3 glow = blurred / weightSum * strength;
    vec3 color = original.rgb + glow;
    float glowAlpha = max(glow.r, max(glow.g, glow.b));
    gl_FragColor = vec4(min(color, vec3(1.0)), min(1.0, original.a + glowAlpha));
}
