// Preset 7: Vintage VHS Tracking Distortion & Noise Glitch
// Simplex 2D noise waves, horizontal displacement, scanlines and chromatic color bleeding.
// Connect video to iChannel0 for an authentic analog VHS tape look!

vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
    return mod289(((x * 34.0) + 1.0) * x);
}

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                        0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                       -0.577350269189626,  // -1.0 + 2.0 * C.x
                        0.024390243902439); // 1.0 / 41.0
    // First corner
    vec2 i  = floor(v + dot(v, C.yy));
    vec2 x0 = v -   i + dot(i, C.xx);

    // Other corners
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    // Permutations
    i = mod289(i);
    vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));

    vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
    m = m * m;
    m = m * m;

    // Gradients: 41 points uniformly over a line, mapped onto a diamond.
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    // Normalise gradients implicitly by scaling m
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);

    // Compute final noise value at P
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    float time = iTime * 2.0;

    // Create large, incidental noise waves
    float noise = max(0.0, snoise(vec2(time, uv.y * 0.3)) - 0.3) * (1.0 / 0.7);

    // Offset by smaller, constant noise waves
    noise = noise + (snoise(vec2(time * 10.0, uv.y * 2.4)) - 0.5) * 0.15;

    // Apply the noise as x displacement for every line
    float xpos = uv.x - noise * noise * 0.25;
    vec4 src = texture(iChannel0, vec2(xpos, uv.y));

    // Fallback pattern if iChannel0 is not connected
    if (src.a < 0.01 || (src.r == 0.0 && src.g == 0.0 && src.b == 0.0)) {
        float bar = floor(uv.x * 7.0);
        vec3 barColor = vec3(0.1);
        if (bar == 0.0) barColor = vec3(0.8, 0.8, 0.8);
        else if (bar == 1.0) barColor = vec3(0.8, 0.8, 0.0);
        else if (bar == 2.0) barColor = vec3(0.0, 0.8, 0.8);
        else if (bar == 3.0) barColor = vec3(0.0, 0.8, 0.0);
        else if (bar == 4.0) barColor = vec3(0.8, 0.0, 0.8);
        else if (bar == 5.0) barColor = vec3(0.8, 0.0, 0.0);
        else barColor = vec3(0.0, 0.0, 0.8);
        src = vec4(barColor, 1.0);
    }

    fragColor = src;

    // Mix in random static noise interference
    fragColor.rgb = mix(fragColor.rgb, vec3(rand(vec2(uv.y * time, time))), noise * 0.3);

    // Apply horizontal scanline pattern every 4 pixels
    if (floor(mod(fragCoord.y * 0.25, 2.0)) == 0.0) {
        fragColor.rgb *= 1.0 - (0.15 * noise);
    }

    // Chromatic aberration / color fringing shift on green and blue channels
    fragColor.g = mix(fragColor.r, texture(iChannel0, vec2(xpos + noise * 0.05, uv.y)).g, 0.25);
    fragColor.b = mix(fragColor.r, texture(iChannel0, vec2(xpos - noise * 0.05, uv.y)).b, 0.25);
}
