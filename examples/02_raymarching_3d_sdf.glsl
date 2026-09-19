// ==============================================================================
// Shader 02: 3D Raymarching SDF (Sphere & Torus, Phong Lighting, Mouse Orbit)
// Compatible with DaVinci Resolve Shadertoy Fuse & Shadertoy.com
// ==============================================================================

// Matrice di rotazione 2D per angolazione visuale
mat2 rot2D(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

// Funzione di distanza con segno (SDF) per una sfera
float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

// Funzione di distanza con segno (SDF) per un toro (ciambella)
float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

// Funzione SDF globale che unisce la sfera e il toro
float sceneSDF(vec3 p) {
    // Sfera pulsante al centro
    float sphere = sdSphere(p, 0.8 + 0.08 * sin(iTime * 2.5));
    
    // Toroide animato che ruota su più assi
    vec3 tp = p;
    tp.xy = rot2D(iTime * 0.7) * tp.xy;
    tp.yz = rot2D(iTime * 0.5) * tp.yz;
    float torus = sdTorus(tp, vec2(1.3, 0.22));
    
    return min(sphere, torus);
}

// Calcolo del vettore normale sulla superficie tramite gradiente numerico
vec3 calcNormal(vec3 p) {
    const float h = 0.001;
    const vec2 k = vec2(1.0, -1.0);
    return normalize(
        k.xyy * sceneSDF(p + k.xyy * h) +
        k.yyx * sceneSDF(p + k.yyx * h) +
        k.yxy * sceneSDF(p + k.yxy * h) +
        k.xxx * sceneSDF(p + k.xxx * h)
    );
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Coordinate normalizzate e centrate rispetto alla risoluzione
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 mouse = (iMouse.xy - 0.5 * iResolution.xy) / iResolution.y;
    
    // Configurazione raggio fotocamera (Ray Origin & Ray Direction)
    vec3 ro = vec3(0.0, 0.0, -3.6);
    vec3 rd = normalize(vec3(uv, 1.2));
    
    // Rotazione telecamera: controllata dal mouse se premuto, o automatica
    if (iMouse.z > 0.0) {
        ro.yz = rot2D(mouse.y * 3.0) * ro.yz;
        ro.xz = rot2D(-mouse.x * 3.0) * ro.xz;
        rd.yz = rot2D(mouse.y * 3.0) * rd.yz;
        rd.xz = rot2D(-mouse.x * 3.0) * rd.xz;
    } else {
        ro.xz = rot2D(iTime * 0.35) * ro.xz;
        rd.xz = rot2D(iTime * 0.35) * rd.xz;
    }
    
    // Ciclo di Raymarching (Sphere Tracing)
    float t = 0.0;
    float d = 0.0;
    for (int i = 0; i < 80; i++) {
        vec3 p = ro + rd * t;
        d = sceneSDF(p);
        if (d < 0.001 || t > 20.0) break;
        t += d;
    }
    
    // Sfondo a gradiente profondo
    vec3 col = mix(vec3(0.04, 0.04, 0.12), vec3(0.12, 0.18, 0.32), uv.y + 0.5);
    
    // Ombreggiatura Phong se il raggio colpisce un oggetto
    if (t < 20.0) {
        vec3 p = ro + rd * t;
        vec3 n = calcNormal(p);
        vec3 lightDir = normalize(vec3(1.2, 1.6, -1.0));
        
        // Componenti Ambientale e Diffusa
        float diff = max(dot(n, lightDir), 0.0);
        float amb = 0.15;
        
        // Componente Speculare (Blinn-Phong)
        vec3 viewDir = -rd;
        vec3 halfDir = normalize(lightDir + viewDir);
        float spec = pow(max(dot(n, halfDir), 0.0), 32.0);
        
        // Colore iridescente del materiale in base alla posizione e al tempo
        vec3 matCol = 0.5 + 0.5 * cos(vec3(0.0, 1.2, 2.4) + p.y * 2.0 + iTime);
        col = (amb + diff) * matCol + spec * vec3(1.0, 0.95, 0.85);
    }
    
    fragColor = vec4(col, 1.0);
}
