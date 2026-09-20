// Example 05: Texture Ripple & Fluid Distortion
// Demonstrates: iChannel0 texture sampling, UV deformation, and graceful fallback
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p = uv * 2.0 - 1.0;
    p.x *= iResolution.x / iResolution.y;

    // Concentric ripple propagation
    float dist = length(p);
    float wave = sin(dist * 18.0 - iTime * 4.5) * 0.025;
    vec2 warpUV = uv + (p / (dist + 0.0001)) * wave;

    // Sample the input connected to iChannel0
    vec4 tex = texture(iChannel0, warpUV);

    // Graceful fallback: If iChannel0 is not connected (alpha=0 or fully black),
    // display an animated geometric test card pattern
    if (tex.a < 0.01 || (tex.r == 0.0 && tex.g == 0.0 && tex.b == 0.0))
    {
        vec3 col = 0.5 + 0.5 * cos(iTime + warpUV.xyx + vec3(0.0, 2.0, 4.0));
        float grid = step(0.02, mod(warpUV.x * 10.0, 1.0)) * step(0.02, mod(warpUV.y * 10.0, 1.0));
        tex = vec4(col * (0.8 + 0.2 * grid), 1.0);
    }

    fragColor = tex;
}
