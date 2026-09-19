// ==============================================================================
// Shader 03: Cyberpunk Neon Grid & Synthwave Sunset
// Compatible with DaVinci Resolve Shadertoy Fuse & Shadertoy.com
// ==============================================================================

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Coordinate normalizzate centrate rispetto alla risoluzione
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    // Spazio profondo di sfondo
    vec3 col = vec3(0.015, 0.01, 0.04);
    
    // Sole retrò anni '80
    vec2 sunPos = vec2(0.0, 0.08);
    float sunDist = length(uv - sunPos);
    if (sunDist < 0.35 && uv.y > sunPos.y - 0.35) {
        // Tagli orizzontali del sole
        float bars = step(0.025, fract((uv.y - sunPos.y) * 16.0));
        float sunGrad = (uv.y - (sunPos.y - 0.35)) / 0.7;
        vec3 sunCol = mix(vec3(1.0, 0.1, 0.4), vec3(1.0, 0.85, 0.1), sunGrad);
        if (bars > 0.5 || uv.y > 0.0) {
            col = mix(col, sunCol, smoothstep(0.35, 0.34, sunDist));
        }
    }
    // Alone luminoso diffuso attorno al sole
    col += vec3(1.0, 0.25, 0.5) * 0.12 / (sunDist + 0.1);
    
    // Griglia prospettica neon sul piano stradale (quando uv.y < 0.0)
    if (uv.y < 0.0) {
        float pZ = 0.35 / (-uv.y);
        float pX = uv.x * pZ;
        
        // Movimento in avanti con scorrimento temporale
        pZ += iTime * 2.5;
        
        // Linee della griglia procedurale
        vec2 grid = abs(fract(vec2(pX, pZ)) - 0.5);
        float lineDist = min(grid.x, grid.y);
        float gridLine = smoothstep(0.07, 0.0, lineDist);
        
        // Nebbia prospettica verso l'orizzonte
        float depthFog = exp(-pZ * 0.08);
        vec3 gridCol = mix(vec3(0.0, 0.8, 1.0), vec3(1.0, 0.05, 0.8), sin(pZ * 0.25) * 0.5 + 0.5);
        
        col += gridCol * gridLine * depthFog * 2.2;
        col += vec3(0.0, 0.2, 0.5) * (-uv.y * 0.8);
    }
    
    // Linea orizzontale brillante di convergenza all'infinito
    float horizonGlow = 0.004 / abs(uv.y);
    col += vec3(0.0, 0.85, 1.0) * clamp(horizonGlow, 0.0, 1.0);
    
    fragColor = vec4(col, 1.0);
}
