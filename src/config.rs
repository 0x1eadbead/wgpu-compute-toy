use serde;

#[derive(Clone, Debug, serde::Serialize, serde::Deserialize)]
pub struct Config {
    pub shader_path: String,
    pub triangle: [[f32; 2]; 3],
    pub triangle_wh_ratio: f32,
    pub rot: [f32; 3],
    pub scale: f32,
    pub translation: [f32; 3],
    pub screen_width: u32,
    pub screen_height: u32,
    pub compute_width: u32,
    pub compute_height: u32,
    pub blit_shader: Option<String>,
    pub blit_num_vertices: u32,
}

pub static mut G_CONFIG: std::sync::Mutex<Option<Config>> = std::sync::Mutex::new(None);