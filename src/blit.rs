use crate::context::WgpuContext;
use wgpu::util::DeviceExt;
use super::config;

#[rustfmt::skip]
pub const OPENGL_TO_WGPU_MATRIX: cgmath::Matrix4<f32> = cgmath::Matrix4::new(
    1.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 0.5, 0.5,
    0.0, 0.0, 0.0, 1.0,
);

pub const DEFAULT_BLIT_SHADER: &str = include_str!("blit.wgsl");

#[derive(Copy, Clone, Debug)]
pub enum ColourSpace {
    Linear,
    Rgbe,
}

#[repr(C)]
#[derive(Debug, Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
struct MapperUniform {
    vertices: [[f32; 4]; 3],
    transform: [[f32; 4]; 4],
    triangle_wh_ratio: f32,
    _padding: [f32; 3],
    resolution: [u32; 2],
    _padding2: [u32; 2],
}

impl MapperUniform {
    fn new() -> Self {
        use cgmath::SquareMatrix;
        Self {
            vertices: [[-0.5, -0.5, 0.0, 1.0], [0.0, 0.5, 0.0, 1.0], [0.5, -0.5, 0.0, 1.0]],
            transform: cgmath::Matrix4::identity().into(),
            triangle_wh_ratio: 1.0,
            _padding: Default::default(),
            resolution: [800, 600],
            _padding2: Default::default(),
        }
    }

    /*fn update_view_proj(&mut self, camera: &Camera) {
        self.view_proj = camera.build_view_projection_matrix().into();
    }*/
}

pub struct Blitter {
    render_pipeline: wgpu::RenderPipeline,
    render_bind_group: wgpu::BindGroup,
    dest_format: wgpu::TextureFormat,
    mapper_uniform: MapperUniform,
    mapper_buffer: wgpu::Buffer,
    mapper_bind_group: wgpu::BindGroup,
}

impl Blitter {
    pub fn new(
        wgpu: &WgpuContext,
        src: &wgpu::TextureView,
        src_space: ColourSpace,
        dest_format: wgpu::TextureFormat,
        filter: wgpu::FilterMode,
        width: u32,
        height: u32,
        shader_source: Option<&str>,
    ) -> Self {
        let mut mapper_uniform = MapperUniform::new();
        let mapper_buffer = wgpu.device.create_buffer_init(
            &wgpu::util::BufferInitDescriptor {
                label: Some("Mapper Buffer"),
                contents: bytemuck::cast_slice(&[mapper_uniform]),
                usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
            }
        );

        let mapper_bind_group_layout = wgpu.device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
        entries: &[
            wgpu::BindGroupLayoutEntry {
                    binding: 0,
                    visibility: wgpu::ShaderStages::VERTEX,
                    ty: wgpu::BindingType::Buffer {
                        ty: wgpu::BufferBindingType::Uniform,
                        has_dynamic_offset: false,
                        min_binding_size: None,
                    },
                    count: None,
                }
            ],
            label: Some("mapper_bind_group_layout"),
        });

        let mapper_bind_group = wgpu.device.create_bind_group(&wgpu::BindGroupDescriptor {
            layout: &mapper_bind_group_layout,
            entries: &[
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: mapper_buffer.as_entire_binding(),
                }
            ],
            label: Some("mapper_bind_group"),
        });

        let shader_text = shader_source.unwrap_or(DEFAULT_BLIT_SHADER);

        let new_shader = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
            wgpu
                .device
                .create_shader_module(wgpu::ShaderModuleDescriptor {
                    label: None,
                    source: wgpu::ShaderSource::Wgsl(shader_text.into()),
                })
        }));

        if let Err(be) = &new_shader {
            if let Some(e) = be.downcast_ref::<Box<dyn std::error::Error>>() {
                log::error!("Failed to update blitter shader: {e}");
            } else {
                log::error!("Failed to update blitter shader");
            }
        }

        let render_shader = new_shader.unwrap_or_else(|_| {
            wgpu
                .device
                .create_shader_module(wgpu::ShaderModuleDescriptor {
                    label: None,
                    source: wgpu::ShaderSource::Wgsl(DEFAULT_BLIT_SHADER.into()),
                })
        });

        let filterable = filter == wgpu::FilterMode::Linear;
        let render_bind_group_layout =
            wgpu.device
                .create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
                    label: None,
                    entries: &[
                        wgpu::BindGroupLayoutEntry {
                            binding: 0,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Texture {
                                multisampled: false,
                                sample_type: wgpu::TextureSampleType::Float { filterable },
                                view_dimension: wgpu::TextureViewDimension::D2,
                            },
                            count: None,
                        },
                        wgpu::BindGroupLayoutEntry {
                            binding: 1,
                            visibility: wgpu::ShaderStages::FRAGMENT,
                            ty: wgpu::BindingType::Sampler(if filterable {
                                wgpu::SamplerBindingType::Filtering
                            } else {
                                wgpu::SamplerBindingType::NonFiltering
                            }),
                            count: None,
                        },
                    ],
                });
        let mut b = Blitter {
            render_bind_group: wgpu.device.create_bind_group(&wgpu::BindGroupDescriptor {
                label: None,
                layout: &render_bind_group_layout,
                entries: &[
                    wgpu::BindGroupEntry { binding: 0, resource: wgpu::BindingResource::TextureView(src) },
                    wgpu::BindGroupEntry { binding: 1, resource: wgpu::BindingResource::Sampler(&wgpu.device.create_sampler(&wgpu::SamplerDescriptor {
                        min_filter: filter,
                        mag_filter: filter,
                        ..Default::default()
                    })) },
                ],
            }),
            render_pipeline: wgpu.device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
                label: None,
                layout: Some(&wgpu.device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
                    label: None,
                    bind_group_layouts: &[
                        &render_bind_group_layout,
                        &mapper_bind_group_layout,
                    ],
                    push_constant_ranges: &[],
                })),
                vertex: wgpu::VertexState {
                    module: &render_shader,
                    entry_point: "vs_main",
                    buffers: &[],
                },
                fragment: Some(wgpu::FragmentState {
                    module: &render_shader,
                    entry_point: match (src_space, dest_format) {
                        // FIXME use sRGB viewFormats instead once the API stabilises
                        (ColourSpace::Linear, wgpu::TextureFormat::Bgra8Unorm) => "fs_main_linear_to_srgb",
                        (ColourSpace::Linear, wgpu::TextureFormat::Rgba8Unorm) => "fs_main_linear_to_srgb",
                        (ColourSpace::Linear, wgpu::TextureFormat::Bgra8UnormSrgb) => "fs_main", // format automatically performs sRGB encoding
                        (ColourSpace::Linear, wgpu::TextureFormat::Rgba8UnormSrgb) => "fs_main",
                        (ColourSpace::Linear, wgpu::TextureFormat::Rgba16Float) => "fs_main",
                        (ColourSpace::Rgbe, wgpu::TextureFormat::Rgba16Float) => "fs_main_rgbe_to_linear",
                        _ => panic!("Blitter: unrecognised conversion from {src_space:?} to {dest_format:?}")
                    },
                    targets: &[Some(dest_format.into())],
                }),
                primitive: wgpu::PrimitiveState::default(),
                depth_stencil: None,
                multisample: wgpu::MultisampleState::default(),
                multiview: None,
            }),
            dest_format,
            mapper_uniform: mapper_uniform,
            mapper_buffer: mapper_buffer,
            mapper_bind_group: mapper_bind_group,
        };
        unsafe {
            let lc = {&config::G_CONFIG}.lock().unwrap();
            if lc.is_some() {
                let cc = lc.clone();
                b.update(wgpu, &cc.unwrap());
            }
        }

        b
    }

    pub fn blit(&self, wgpu: &WgpuContext, encoder: &mut wgpu::CommandEncoder, view: &wgpu::TextureView) {
        wgpu.queue.write_buffer(&self.mapper_buffer, 0, bytemuck::cast_slice(&[self.mapper_uniform]));
        let mut render_pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
            label: None,
            color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                view,
                resolve_target: None,
                ops: wgpu::Operations {
                    load: wgpu::LoadOp::Clear(wgpu::Color::BLACK),
                    store: true,
                },
            })],
            depth_stencil_attachment: None,
        });
        render_pass.set_pipeline(&self.render_pipeline);
        render_pass.set_bind_group(0, &self.render_bind_group, &[]);
        render_pass.set_bind_group(1, &self.mapper_bind_group, &[]);
        render_pass.draw(0..3, 0..1);
    }

    pub fn blit_n(&self, wgpu: &WgpuContext, encoder: &mut wgpu::CommandEncoder, view: &wgpu::TextureView, num_vertices: u32) {
        wgpu.queue.write_buffer(&self.mapper_buffer, 0, bytemuck::cast_slice(&[self.mapper_uniform]));
        let mut render_pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
            label: None,
            color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                view,
                resolve_target: None,
                ops: wgpu::Operations {
                    load: wgpu::LoadOp::Clear(wgpu::Color::BLACK),
                    store: true,
                },
            })],
            depth_stencil_attachment: None,
        });
        render_pass.set_pipeline(&self.render_pipeline);
        render_pass.set_bind_group(0, &self.render_bind_group, &[]);
        render_pass.set_bind_group(1, &self.mapper_bind_group, &[]);
        render_pass.draw(0..num_vertices, 0..1);
    }

    pub fn create_texture(
        &self,
        wgpu: &WgpuContext,
        width: u32,
        height: u32,
        mip_level_count: u32,
    ) -> wgpu::Texture {
        let texture = wgpu.device.create_texture(&wgpu::TextureDescriptor {
            size: wgpu::Extent3d {
                width,
                height,
                depth_or_array_layers: 1,
            },
            mip_level_count,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: self.dest_format,
            usage: wgpu::TextureUsages::TEXTURE_BINDING | wgpu::TextureUsages::RENDER_ATTACHMENT,
            label: None,
            view_formats: &[],
        });
        let mut encoder = wgpu.device.create_command_encoder(&Default::default());
        let views: Vec<wgpu::TextureView> = (0..mip_level_count)
            .map(|base_mip_level| {
                texture.create_view(&wgpu::TextureViewDescriptor {
                    base_mip_level,
                    mip_level_count: Some(1),
                    ..Default::default()
                })
            })
            .collect();
        self.blit(wgpu, &mut encoder, &views[0]);
        for target_mip in 1..mip_level_count as usize {
            Blitter::new(
                wgpu,
                &views[target_mip - 1],
                ColourSpace::Linear,
                self.dest_format,
                wgpu::FilterMode::Linear,
                width,
                height,
                None,
            )
            .blit(wgpu, &mut encoder, &views[target_mip]);
        }
        wgpu.queue.submit(Some(encoder.finish()));
        texture
    }

    pub fn update(&mut self, wgpu: &WgpuContext, config: &config::Config) {
        self.mapper_uniform.vertices[0][0] = config.triangle[0][0];
        self.mapper_uniform.vertices[0][1] = config.triangle[0][1];
        self.mapper_uniform.vertices[1][0] = config.triangle[1][0];
        self.mapper_uniform.vertices[1][1] = config.triangle[1][1];
        self.mapper_uniform.vertices[2][0] = config.triangle[2][0];
        self.mapper_uniform.vertices[2][1] = config.triangle[2][1];

        use cgmath::{Rad, Deg};
        let rotx = cgmath::Matrix4::<f32>::from_angle_x(Deg(config.rot[0]));
        let roty = cgmath::Matrix4::<f32>::from_angle_y(Deg(config.rot[1]));
        let rotz = cgmath::Matrix4::<f32>::from_angle_z(Deg(config.rot[2]));

        let scale = cgmath::Matrix4::<f32>::from_scale(config.scale);
        let translation = cgmath::Matrix4::<f32>::from_translation(config.translation.into());
        self.mapper_uniform.triangle_wh_ratio = config.triangle_wh_ratio;
        self.mapper_uniform.transform = (OPENGL_TO_WGPU_MATRIX * translation * scale * (rotx * roty * rotz)).into();

        println!("New triangle: {:#?}", &self.mapper_uniform.vertices);
        println!("New triangle: {:#?}", &self.mapper_uniform.triangle_wh_ratio);
        println!("New transform: {:#?}", &self.mapper_uniform.transform);
    }
}
