// ==============================================================================
// Shader 01: Procedural 2D Plasma & Geometric Wave Interference
// Compatible with DaVinci Resolve Shadertoy Fuse & Shadertoy.com
// ==============================================================================

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Coordinate normalizzate centrate (-1.0 a +1.0 sull'asse Y)
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    float t = iTime * 0.8;
    
    // Interferenza di onde sinusoidali multiple
    float v1 = sin(uv.x * 10.0 + t);
    float v2 = sin(uv.y * 10.0 + t * 1.2);
    float v3 = sin((uv.x + uv.y) * 10.0 + t * 0.5);
    
    // Centro mobile orbitante
    float cx = uv.x + 0.5 * sin(t * 0.3);
    float cy = uv.y + 0.5 * cos(t * 0.5);
    float v4 = sin(sqrt(100.0 * (cx * cx + cy * cy) + 1.0) + t * 1.5);
    
    // Media delle onde
    float v = (v1 + v2 + v3 + v4) * 0.25;
    
    // Tavolozza cromatica psichedelica fluida
    vec3 col = 0.5 + 0.5 * cos(vec3(v * 3.14159 + 0.0, v * 3.14159 + 2.0, v * 3.14159 + 4.0) + t * 0.3);
    
    // Vignettatura cinematografica ai bordi del fotogramma
    vec2 q = fragCoord / iResolution.xy;
    col *= 0.5 + 0.5 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.25);
    
    // Uscita colore RGBA
    fragColor = vec4(col, 1.0);
}
