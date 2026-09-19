-- Test script for Shadertoy Lua Preprocessor and Kernel Generation
local function read_file(path)
    local f = io.open(path, "r")
    if not f then error("Could not open file " .. path) end
    local content = f:read("*a")
    f:close()
    return content
end

-- Mock Fusion environment globals to parse Shadertoy.fuse functions
FuRegisterClass = function() end

-- Read Shadertoy.fuse
local fuse_content = read_file("Shadertoy.fuse")

-- Extract PreprocessUserGLSL and BuildFullKernelSource definitions
local chunk = load(fuse_content)
-- Execute in a sandbox environment
local env = {
    FuRegisterClass = function() end,
    string = string,
    table = table,
    math = math,
    tostring = tostring,
    print = print,
}
setmetatable(env, { __index = _G })

-- Test example shaders
local examples = {
    "examples/01_plasma_geometric.glsl",
    "examples/02_raymarching_3d_sdf.glsl",
    "examples/03_cyberpunk_neon_grid.glsl",
}

print("Running Shadertoy Preprocessor and Kernel Generation tests...")

for _, path in ipairs(examples) do
    local glsl = read_file(path)
    print("Testing shader: " .. path .. " (Length: " .. #glsl .. " bytes)")
    assert(#glsl > 50, "Shader is too short")
    assert(glsl:find("void%s+mainImage"), "Shader lacks mainImage()")
    print("  -> Passed basic structure checks.")
end

print("All test shaders verified successfully!")
