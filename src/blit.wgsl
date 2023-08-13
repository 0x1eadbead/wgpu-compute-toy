// https://github.com/gfx-rs/wgpu/blob/master/wgpu/examples/mipmap/blit.wgsl

struct MapperUniform {
    vertices: array<vec4<f32>, 3>,
    transform: mat4x4<f32>
}

struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) tex_coords: vec2<f32>
};

@group(1) @binding(0)
var<uniform> mapper: MapperUniform;

@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOutput {
    var out: VertexOutput;
    var pos: vec2<f32>;
    var tex: vec2<f32>;

    if (vertex_index == 0u) {
        tex = vec2<f32>(0.0, 1.0);
    } else if (vertex_index == 1u) {
        tex = vec2<f32>(0.5, 0.0);
    } else if (vertex_index == 2u) {
        tex = vec2<f32>(1.0, 1.0);
    }

    pos = mapper.vertices[vertex_index].xy;

    // let x = i32(vertex_index) / 2;
    // let y = i32(vertex_index) & 1;
    // let tc = vec2<f32>(
    //     f32(x) * 2.0,
    //     f32(y) * 2.0
    // );
    out.position = mapper.transform * vec4<f32>(
        pos.x,
        pos.y,
        0.0, 1.0
    );
    out.tex_coords = tex;
    return out;
}

@group(0) @binding(0) var r_color: texture_2d<f32>;
@group(0) @binding(1) var r_sampler: sampler;

fn srgb_to_linear(rgb: vec3<f32>) -> vec3<f32> {
    return select(
        pow((rgb + 0.055) * (1.0 / 1.055), vec3<f32>(2.4)),
        rgb * (1.0/12.92),
        rgb <= vec3<f32>(0.04045));
}

fn linear_to_srgb(rgb: vec3<f32>) -> vec3<f32> {
    return select(
        1.055 * pow(rgb, vec3(1.0 / 2.4)) - 0.055,
        rgb * 12.92,
        rgb <= vec3<f32>(0.0031308));
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    return textureSample(r_color, r_sampler, in.tex_coords);
}

@fragment
fn fs_main_linear_to_srgb(in: VertexOutput) -> @location(0) vec4<f32> {
    let rgba = textureSample(r_color, r_sampler, in.tex_coords);
    return vec4<f32>(linear_to_srgb(rgba.rgb), rgba.a);
}

@fragment
fn fs_main_rgbe_to_linear(in: VertexOutput) -> @location(0) vec4<f32> {
    let rgbe = textureSample(r_color, r_sampler, in.tex_coords);
    return vec4<f32>(rgbe.rgb * exp2(rgbe.a * 255. - 128.), 1.);
}
