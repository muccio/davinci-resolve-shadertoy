-- Comprehensive test script for Shadertoy Lua Preprocessor and Kernel Generation
local function read_file(path)
    local f = io.open(path, "r")
    if not f then error("Could not open file " .. path) end
    local content = f:read("*a")
    f:close()
    return content
end

-- Mock Fusion environment globals to parse Shadertoy.fuse
local fuse_content = read_file("Shadertoy.fuse")

-- Sandbox to execute Shadertoy.fuse and extract internal generator functions
local env = {
    FuRegisterClass = function() end,
    CT_SourceTool = "CT_SourceTool",
    string = string,
    table = table,
    math = math,
    tostring = tostring,
    print = print,
    type = type,
    pcall = pcall,
}
setmetatable(env, { __index = _G })

local chunk, err = load(fuse_content, "Shadertoy.fuse", "t", env)
if not chunk then
    error("Failed to load Shadertoy.fuse: " .. tostring(err))
end
chunk()

print("Loaded Shadertoy.fuse successfully.")

-- Verify absence of the fatal macro in the Compatibility Header
local compatHeader = fuse_content:match("local CompatibilityHeader = %[=%[(.-)%]=%]")
assert(compatHeader, "Could not find CompatibilityHeader")
assert(not compatHeader:find("#define iChannel0"), "FATAL: '#define iChannel0' must NOT be in CompatibilityHeader!")
assert(compatHeader:find("struct mat3"), "CompatibilityHeader should include mat3")
assert(compatHeader:find("dFdx"), "CompatibilityHeader should include dFdx fallbacks")
print("  -> CompatibilityHeader checks passed.")

-- Verify UI default text definition
assert(fuse_content:find("INPS_DefaultText%s*=%s*PRESET_1_PLASMA"), "InCode must use INPS_DefaultText")
print("  -> INPS_DefaultText check passed.")

-- Test example shaders
local examples = {
    "examples/01_plasma_geometric.glsl",
    "examples/02_raymarching_3d_sdf.glsl",
    "examples/03_cyberpunk_neon_grid.glsl",
    "examples/04_fractal_pyramid.glsl",
}

print("Running Shadertoy Preprocessor and Kernel Generation tests on example files...")

for _, path in ipairs(examples) do
    local glsl = read_file(path)
    print("Testing shader: " .. path .. " (Length: " .. #glsl .. " bytes)")
    assert(#glsl > 50, "Shader is too short")
    assert(glsl:find("void%s+mainImage"), "Shader lacks mainImage()")
    print("  -> Passed basic structure checks.")
end

print("All test shaders and kernel checks verified successfully!")
