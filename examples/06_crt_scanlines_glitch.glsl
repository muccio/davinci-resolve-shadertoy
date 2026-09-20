// Example 06: Vintage CRT Monitor & Chromatic Aberration
// Demonstrates: iChannel0 multi-tap RGB sampling, barrel curvature, and scanlines
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // CRT Barrel Curvature
    vec2 cc = uv - 0.5;
    float dist = dot(cc, cc);
    vec2 crtUV = uv + cc * (dist * 0.18);

    // Border vignette mask
    if (crtUV.x < 0.0 || crtUV.x > 1.0 || crtUV.y < 0.0 || crtUV.y > 1.0)
    {
        fragColor = vec4(0.02, 0.02, 0.02, 1.0);
        return;
    }

    // Chromatic aberration (RGB shift)
    float shift = 0.004 * (1.0 + dist * 2.0);
    vec4 colR = texture(iChannel0, crtUV + vec2(shift, 0.0));
    vec4 colG = texture(iChannel0, crtUV);
    vec4 colB = texture(iChannel0, crtUV - vec2(shift, 0.0));
    vec4 col = vec4(colR.r, colG.g, colB.b, colG.a);

    // Fallback if no input connected
    if (col.a < 0.01 || (col.r == 0.0 && col.g == 0.0 && col.b == 0.0))
    {
        // Retro color bars test signal
        float bar = floor(crtUV.x * 7.0);
        vec3 barColor = vec3(0.0);
        if (bar == 0.0) barColor = vec3(0.8, 0.8, 0.8);
        else if (bar == 1.0) barColor = vec3(0.8, 0.8, 0.0);
        else if (bar == 2.0) barColor = vec3(0.0, 0.8, 0.8);
        else if (bar == 3.0) barColor = vec3(0.0, 0.8, 0.0);
        else if (bar == 4.0) barColor = vec3(0.8, 0.0, 0.8);
        else if (bar == 5.0) barColor = vec3(0.8, 0.0, 0.0);
        else barColor = vec3(0.0, 0.0, 0.8);
        col = vec4(barColor, 1.0);
    }

    // Scanlines
    float scanline = sin(crtUV.y * iResolution.y * 1.5) * 0.08;
    col.rgb -= scanline;

    // Corner vignette
    float vig = 16.0 * crtUV.x * crtUV.y * (1.0 - crtUV.x) * (1.0 - crtUV.y);
    col.rgb *= clamp(pow(vig, 0.25), 0.0, 1.0);

    // Subtle flicker
    col.rgb *= 0.97 + 0.03 * sin(iTime * 120.0);

    fragColor = col;
}
