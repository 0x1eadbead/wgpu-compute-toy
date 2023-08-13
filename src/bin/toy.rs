use serde::{Deserialize, Serialize};
use std::error::Error;
use wgputoy::context::init_wgpu;
use wgputoy::WgpuToyRenderer;
use wgputoy::config;
use std::sync::{Arc, Mutex};
use notify::{Config, RecommendedWatcher, RecursiveMode, Watcher};

#[derive(Serialize, Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
struct ShaderMeta {
    uniforms: Vec<Uniform>,
    textures: Vec<Texture>,
    #[serde(default)]
    float32_enabled: bool,
}

#[derive(Serialize, Deserialize, Debug)]
struct Uniform {
    name: String,
    value: f32,
}

#[derive(Serialize, Deserialize, Debug)]
struct Texture {
    img: String,
}

async fn init(config: &config::Config) -> Result<WgpuToyRenderer, Box<dyn Error>> {

    let wgpu = init_wgpu(config.screen_width, config.screen_height, "").await?;
    let mut wgputoy = WgpuToyRenderer::new(wgpu, config.compute_width, config.compute_height);
    let filename = config.shader_path.clone();
    let shader = std::fs::read_to_string(&filename)?;

    // let client = reqwest_middleware::ClientBuilder::new(reqwest::Client::new())
    //     .with(reqwest_middleware_cache::Cache {
    //         mode: reqwest_middleware_cache::CacheMode::Default,
    //         cache_manager: reqwest_middleware_cache::managers::CACacheManager::default(),
    //     })
    //     .build();

    if let Ok(json) = std::fs::read_to_string(std::format!("{filename}.json")) {
        let metadata: ShaderMeta = serde_json::from_str(&json)?;
        println!("{:?}", metadata);

        // for (i, texture) in metadata.textures.iter().enumerate() {
        //     let url = if texture.img.starts_with("http") {
        //         texture.img.clone()
        //     } else {
        //         std::format!("https://compute.toys/{}", texture.img)
        //     };
        //     let resp = client.get(&url).send().await?;
        //     let img = resp.bytes().await?.to_vec();
        //     if texture.img.ends_with(".hdr") {
        //         wgputoy.load_channel_hdr(i, &img)?;
        //     } else {
        //         wgputoy.load_channel(i, &img);
        //     }
        // }

        let uniform_names: Vec<String> = metadata.uniforms.iter().map(|u| u.name.clone()).collect();
        let uniform_values: Vec<f32> = metadata.uniforms.iter().map(|u| u.value).collect();
        if !uniform_names.is_empty() {
            wgputoy.set_custom_floats(uniform_names, uniform_values);
        }

        wgputoy.set_pass_f32(metadata.float32_enabled);
    }

    if let Some(source) = wgputoy.preprocess_async(&shader).await {
        println!("{}", source.source);
        wgputoy.compile(source);
    }

    wgputoy.update(&config);

    Ok(wgputoy)
}

#[derive(Clone, Default)]
struct Shader {
    text: String,
    generation: u64,
}

#[derive(Clone)]
struct SharedConfig {
    config: config::Config,
    generation: u64
}

fn main() -> Result<(), Box<dyn Error>> {
    let config_path = if std::env::args().len() > 1 {
        std::env::args().nth(1).unwrap()
    } else {
        "config.json".into()
    };
    let config_text = std::fs::read_to_string(&config_path).unwrap();
    let config: config::Config = serde_json::from_str(&config_text).unwrap();

    println!("Starting with config: {:#?}", config);

    let runtime = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()?;

    let mut wgputoy = runtime.block_on(init(&config))?;

    let screen_size = wgputoy.wgpu.window.inner_size();
    let start_time = std::time::Instant::now();
    let event_loop = std::mem::take(&mut wgputoy.wgpu.event_loop).unwrap();
    let device_clone = wgputoy.wgpu.device.clone();

    let mut new_shader: Arc<Mutex<Shader>> = Arc::new(Default::default());
    let new_shader_clone = new_shader.clone();

    let shader_path = config.shader_path.clone();

    // shader watcher
    std::thread::spawn(move || loop {
        let filename = shader_path.clone();

        let (tx, rx) = std::sync::mpsc::channel();
        let mut watcher = RecommendedWatcher::new(tx, Config::default()).unwrap();
        watcher.watch(filename.as_ref(), RecursiveMode::NonRecursive).unwrap();

        for res in rx {
            if res.is_err() {
                continue;
            }

            let res = res.unwrap();

            if let notify::EventKind::Modify(_) = res.kind {

                let _ = std::fs::read_to_string(&filename).map(|text|
                {
                    let mut shared_shader = new_shader_clone.lock().unwrap();
                    shared_shader.generation += 1;
                    shared_shader.text = text;
                });
            }
        }
    });

    let mut new_config: Arc<Mutex<SharedConfig>> = Arc::new(Mutex::new(
        SharedConfig { config: config.clone(), generation: 1 } // generation hack to always apply on first frame
    ));
    let new_config_clone = new_config.clone();

    std::thread::spawn(move || loop {
        let filename = config_path.clone();

        let (tx, rx) = std::sync::mpsc::channel();
        let mut watcher = RecommendedWatcher::new(tx, Config::default()).unwrap();
        watcher.watch(filename.as_ref(), RecursiveMode::NonRecursive).unwrap();

        for res in rx {
            if res.is_err() {
                continue;
            }

            let res = res.unwrap();

            if let notify::EventKind::Modify(_) = res.kind {

                let _ = std::fs::read_to_string(&filename).map(|text|
                {
                    if let Ok(config) = serde_json::from_str(&text) {
                        let mut shared_config = new_config_clone.lock().unwrap();
                        shared_config.generation += 1;
                        shared_config.config = config;
                    }
                });
            }
        }
    });
    std::thread::spawn(move || loop {
        device_clone.poll(wgpu::Maintain::Wait);
    });

    let mut last_shader_generation: u64 = 0;
    let mut last_config_generation: u64 = 0;

    event_loop.run(move |event, _, control_flow| {
        *control_flow = winit::event_loop::ControlFlow::Poll;
        match event {
            winit::event::Event::RedrawRequested(_) => {
                let time = start_time.elapsed().as_micros() as f32 * 1e-6;

                if let Ok(shared_config) = new_config.lock() {
                    if shared_config.generation > last_config_generation {
                        wgputoy.update(&shared_config.config);
                        last_config_generation = shared_config.generation;
                    }
                }

                let mut new_text = Option::None;

                if let Ok(shader) = new_shader.lock() {
                    if shader.generation > last_shader_generation {
                        last_shader_generation = shader.generation;
                        new_text = Some(shader.text.clone());
                    }
                }

                if let Some(text) = new_text {
                    runtime.block_on(wgputoy.preprocess_async(&text)).map(|preprocessed| {
                        let result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
                            wgputoy.compile(preprocessed);
                        }));

                        if let Err(be) = result {
                            if let Ok(e) = be.downcast::<Box<dyn Error>>() {
                                println!("Failed to update shader: {e}");
                            } else {
                                println!("Failed to update shader");
                            }
                        }
                    });
                }

                wgputoy.set_time_elapsed(time);
                let future = wgputoy.render_async();
                runtime.block_on(future);
            }
            winit::event::Event::MainEventsCleared => {
                wgputoy.wgpu.window.request_redraw();
            }
            winit::event::Event::WindowEvent {
                event: winit::event::WindowEvent::CloseRequested,
                ..
            } => *control_flow = winit::event_loop::ControlFlow::Exit,
            winit::event::Event::WindowEvent {
                event: winit::event::WindowEvent::CursorMoved { position, .. },
                ..
            } => wgputoy.set_mouse_pos(
                position.x as f32 / screen_size.width as f32,
                position.y as f32 / screen_size.height as f32,
            ),
            winit::event::Event::WindowEvent {
                event: winit::event::WindowEvent::Resized(size),
                ..
            } => {
                if size.width != 0 && size.height != 0 {
                    wgputoy.resize(size.width, size.height, 1.);
                }
            }
            winit::event::Event::WindowEvent {
                event: winit::event::WindowEvent::MouseInput { state, .. },
                ..
            } => wgputoy.set_mouse_click(state == winit::event::ElementState::Pressed),
            _ => (),
        }
    });
}
