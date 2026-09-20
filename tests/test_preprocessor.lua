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

-- Verify absence of fatal macro in CompatibilityHeader
local compatHeader = fuse_content:match("local CompatibilityHeader = %[=%[(.-)%]=%]")
assert(compatHeader, "Could not find CompatibilityHeader")
assert(not compatHeader:find("#define iChannel0"), "FATAL: '#define iChannel0' must NOT be in CompatibilityHeader!")
assert(compatHeader:find("struct mat3"), "CompatibilityHeader should include mat3")
assert(compatHeader:find("dFdx"), "CompatibilityHeader should include dFdx fallbacks")
assert(compatHeader:find("struct ShadertoyChannel"), "CompatibilityHeader should include ShadertoyChannel")
assert(compatHeader:find("typedef ShadertoyChannel sampler2D"), "CompatibilityHeader should include sampler2D typedef")
assert(compatHeader:find("wrapCoords"), "CompatibilityHeader should include wrapCoords")
print("  -> CompatibilityHeader checks passed.")

-- Verify UI default text definition
assert(fuse_content:find("INPS_DefaultText%s*=%s*PRESET_1_PLASMA"), "InCode must use INPS_DefaultText")
print("  -> INPS_DefaultText check passed.")

-- Verify multi-channel inputs exist
assert(fuse_content:find('InChannel0 = self:AddInput%("iChannel0"'), "InChannel0 must be registered")
assert(fuse_content:find('InChannel1 = self:AddInput%("iChannel1"'), "InChannel1 must be registered")
assert(fuse_content:find('InChannel2 = self:AddInput%("iChannel2"'), "InChannel2 must be registered")
assert(fuse_content:find('InChannel3 = self:AddInput%("iChannel3"'), "InChannel3 must be registered")
print("  -> Multi-channel input ports check passed.")

-- Verify kernel signature has 4 texture inputs
assert(fuse_content:find("__TEXTURE2D__ iChannel0,%s*__TEXTURE2D__ iChannel1,%s*__TEXTURE2D__ iChannel2,%s*__TEXTURE2D__ iChannel3"),
    "Kernel entry point must take 4 channel inputs")
print("  -> Kernel signature 4-channel check passed.")

-- Verify Compiler Status input exists
assert(fuse_content:find('InCompilerStatus = self:AddInput%("Compiler Status"'), "InCompilerStatus must be registered")
print("  -> InCompilerStatus console control check passed.")

-- Test example shaders
local examples = {
    "examples/01_plasma_geometric.glsl",
    "examples/02_raymarching_3d_sdf.glsl",
    "examples/03_cyberpunk_neon_grid.glsl",
    "examples/04_fractal_pyramid.glsl",
    "examples/05_texture_ripple_warp.glsl",
    "examples/06_crt_scanlines_glitch.glsl",
    "examples/07_vhs_tracking_glitch.glsl",
}

print("Running Shadertoy Preprocessor and Kernel Generation tests on example files...")

-- Extract PreprocessUserGLSL, GetLatestCompilerError, and BuildFullKernelSource from fuse_content
local prep_body = fuse_content:match("(local function PreprocessUserGLSL.-end)\n\nlocal function SimpleHash")
assert(prep_body, "Could not extract PreprocessUserGLSL")
local err_body = fuse_content:match("(local function GetLatestCompilerError.-end)\n\n%-%- ==============================================================================\n%-%- 6%. KERNEL")
assert(err_body, "Could not extract GetLatestCompilerError")
local kernel_body = fuse_content:match("(local function BuildFullKernelSource.-end)\n\n%-%- ==============================================================================\n%-%- 7%. FUSION UI")
assert(kernel_body, "Could not extract BuildFullKernelSource")

local test_sandbox = {
    CompatibilityHeader = compatHeader,
    PRESET_1_PLASMA = "",
    string = string,
    tostring = tostring,
    tonumber = tonumber,
    ipairs = ipairs,
    pairs = pairs,
    os = os,
    io = io,
    math = math,
}
local test_chunk = load(prep_body .. "\n" .. err_body .. "\n" .. kernel_body .. "\nreturn { Preprocess = PreprocessUserGLSL, Build = BuildFullKernelSource, GetError = GetLatestCompilerError }", "test_builder", "t", test_sandbox)
local funcs = test_chunk()

for _, path in ipairs(examples) do
    local glsl = read_file(path)
    print("Testing shader: " .. path .. " (Length: " .. #glsl .. " bytes)")
    assert(#glsl > 50, "Shader is too short")
    assert(glsl:find("void%s+mainImage"), "Shader lacks mainImage()")

    local processed = funcs.Preprocess(glsl)
    assert(processed:find("thread vec4&"), "Preprocess failed to normalize out vec4")

    -- Verify line preservation: line counts must match
    local origLines = select(2, glsl:gsub("\n", "\n"))
    local procLines = select(2, processed:gsub("\n", "\n"))
    assert(origLines == procLines, string.format("Line count mismatch for %s: orig=%d, proc=%d", path, origLines, procLines))

    local fullKernel, prefixLines = funcs.Build(glsl, "TestKernel")
    assert(fullKernel:find("__KERNEL__ void TestKernel"), "Kernel generation failed")
    assert(fullKernel:find("ctx%.iChannel0 = ShadertoyChannel"), "Kernel must initialize iChannel0")
    assert(prefixLines and prefixLines > 100, "Prefix lines must be calculated")
    print("  -> Passed preprocessing and kernel generation (Prefix lines: " .. prefixLines .. ").")
end

-- Test error remapping logic
local mockError = "program_source:250:10: error: invalid type 'vec5'\n  vec5 foo = bar;\n         ^"
local formattedErr = funcs.GetError("TestKernel", 200)
assert(formattedErr:find("Metal"), "GetError must return a formatted error")

print("All test shaders, compiler console checks, and kernel checks verified successfully!")
