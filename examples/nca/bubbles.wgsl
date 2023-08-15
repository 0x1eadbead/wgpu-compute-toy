const NUM_CHANNELS = 12u;

//const DATA_BUFFER_SIZE = u32(SCREEN_WIDTH) * u32(SCREEN_HEIGHT) * NUM_CHANNELS;
const DATA_BUFFER_SIZE = 10972800u; // 1280 * 720 * 12

#storage data_buffer array<f32,DATA_BUFFER_SIZE>
fn hash43(p: float3) -> float4 {
  var p4: float4 = fract(float4(p.xyzx)  * float4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

fn data_buffer_idx(x: u32, y: u32, c: u32) -> u32 {
    return c + (x + y * u32(SCREEN_WIDTH)) * NUM_CHANNELS;
}

fn data_buffer_read_c4(x: u32, y: u32, c: u32) -> float4 {
    let i = data_buffer_idx(x, y, c);
    return float4(data_buffer[i], data_buffer[i + 1u], data_buffer[i + 2u], data_buffer[i + 3u]);
}

fn data_buffer_write_c4(v: float4, x: u32, y: u32, c: u32) {
    let i = data_buffer_idx(x, y, c);
    data_buffer[i] = v[0];
    data_buffer[i+1u] = v[1];
    data_buffer[i+2u] = v[2];
    data_buffer[i+3u] = v[3];
}

fn data_buffer_read_12(x: u32, y: u32) -> array<f32, 12> {
    let idx = data_buffer_idx(x, y, 0u);
    var result: array<f32, 12>;

    for (var i = 0; i < 12; i = i + 1) {
        result[i] = data_buffer[i + i32(idx)];
    }

    return result;
}

fn data_buffer_write_12(x: u32, y: u32, _data: array<f32, 12>) {
    let idx = data_buffer_idx(x, y, 0u);
    var data = _data;

    for (var i = 0; i < 12; i = i + 1) {
        data_buffer[i + i32(idx)] = data[i];
    }
}

var<private> current_index: int2;

fn R(x: i32, y: i32, c: i32) -> float4 {
    return data_buffer_read_c4(u32(current_index.x + x + SCREEN_WIDTH) % u32(SCREEN_WIDTH), u32(current_index.y + y + SCREEN_HEIGHT) % u32(SCREEN_HEIGHT), u32(c));
}


fn F(yi: float4, a: array<float4, 4>, b: array<float4, 4>) -> float4 {
    return
        yi[0] * a[0] + abs(yi[0]) * b[0] +
        yi[1] * a[1] + abs(yi[1]) * b[1] +
        yi[2] * a[2] + abs(yi[2]) * b[2] +
        yi[3] * a[3] + abs(yi[3]) * b[3]
    ;
}

fn f4(x: i32, y: i32, z: i32, w: i32) -> float4 {
    return float4(f32(x), f32(y), f32(z), f32(w));
}

fn M(m0: i32, m1: i32, m2: i32, m3: i32,
    m4: i32, m5:i32, m6: i32, m7: i32,
    m8: i32, m9: i32, m10: i32, m11: i32,
    m12: i32, m13: i32, m14: i32, m15: i32) -> array<float4,4> {
        return array<float4,4>(
            float4(f32(m0), f32(m1), f32(m2), f32(m3)),
            float4(f32(m4), f32(m5), f32(m6), f32(m7)),
            float4(f32(m8), f32(m9), f32(m10), f32(m11)),
            float4(f32(m12), f32(m13), f32(m14), f32(m15)),
        );
    }


  fn updaten(_x: array<f32, 12>, _y: array<f32, 12>) -> array<f32, 12> {
    var weights = array<array<i32, 12>, 48>(
       array<i32, 12>(-22, 3, 8, 5, -1, -2, 16, 2, 0, -2, 3, -4),
       array<i32, 12>(-2, -39, -3, 10, -13, 9, 21, -12, -1, -10, 4, 16),
       array<i32, 12>(-3, -3, -45, 17, -4, 5, 20, -21, 1, -16, 0, 21),
       array<i32, 12>(1, 2, 1, -18, -2, -3, -5, -6, -18, -20, 34, 7),
       array<i32, 12>(3, 5, 4, 23, -41, -12, -15, -4, -12, -2, -6, 14),
       array<i32, 12>(-5, -1, 0, -6, 3, -79, 12, 21, 12, 1, 5, 14),
       array<i32, 12>(-5, -6, -7, 15, 33, 0, -57, 29, -4, -34, 7, 9),
       array<i32, 12>(-4, -3, -3, -6, 3, -38, -20, -87, -29, -3, 9, -7),
       array<i32, 12>(2, 2, -1, 9, -7, -18, 4, 13, -70, -16, 14, -2),
       array<i32, 12>(4, 7, 3, -5, 1, 1, 20, 7, -19, -74, 10, 4),
       array<i32, 12>(7, 6, 4, -14, 18, -3, -8, -16, -17, 13, -53, 11),
       array<i32, 12>(1, 2, 3, 24, -8, -9, 10, 11, -16, -6, -7, -48),
       array<i32, 12>(20, -5, -23, 6, 0, 2, -2, 1, 4, -5, 9, 2),
       array<i32, 12>(-7, 19, 5, 7, -3, -4, 0, 0, 2, 0, 6, 5),
       array<i32, 12>(1, 0, 29, 9, 0, -3, -5, 1, -2, 0, 5, 7),
       array<i32, 12>(-1, -1, -1, 31, 17, -1, 9, -5, 1, -9, 0, 8),
       array<i32, 12>(6, 12, 14, -13, -16, -10, -11, 14, 1, 8, 14, 2),
       array<i32, 12>(0, -1, -1, -5, -8, 8, 1, 7, 8, 0, -3, -5),
       array<i32, 12>(-6, -11, -12, 1, 6, 2, 20, 2, 3, -3, -4, -6),
       array<i32, 12>(-2, -4, -4, 6, 8, 3, 5, -17, 2, 1, 2, 3),
       array<i32, 12>(0, 1, 2, -2, 4, -7, -5, 6, 16, 0, 1, -4),
       array<i32, 12>(0, -1, -2, 8, 23, 4, 0, 5, 18, -32, -4, -7),
       array<i32, 12>(3, 6, 7, 12, 3, -11, -2, -13, -6, 2, 11, 11),
       array<i32, 12>(-8, -13, -14, -20, 0, -3, 10, 2, -5, 2, 2, -5),
       array<i32, 12>(15, -5, -6, -6, 0, 2, -12, -3, 2, 5, -6, -1),
       array<i32, 12>(1, 10, -4, 15, 4, -20, 23, -21, -10, 27, -24, -6),
       array<i32, 12>(-1, -7, 10, 17, -6, -18, 41, -32, -9, 8, -25, -2),
       array<i32, 12>(-3, -5, -6, 2, 3, 0, 2, -3, 1, 4, -11, -2),
       array<i32, 12>(8, 15, 16, 5, -2, -12, -7, -3, 6, -1, -3, 10),
       array<i32, 12>(-10, -15, -14, -11, 3, -20, -1, 2, 25, 3, -15, 1),
       array<i32, 12>(6, 8, 4, 22, -8, 5, -3, -24, -11, -14, 16, 0),
       array<i32, 12>(-6, -7, -7, -6, 24, -4, 7, 15, -11, -19, 17, -29),
       array<i32, 12>(-2, 0, 2, 7, -4, -14, -22, 17, -6, 4, 1, -9),
       array<i32, 12>(2, 0, -2, 0, 6, -13, -7, -18, -10, -7, 13, 16),
       array<i32, 12>(3, 3, 3, 20, 1, 29, 22, -9, -16, 27, 5, 8),
       array<i32, 12>(7, 9, 9, -2, 9, 9, 32, -16, -12, -7, 10, -6),
       array<i32, 12>(-4, -2, 1, 0, 5, 2, -6, 2, -1, 2, 2, -2),
       array<i32, 12>(3, 0, 4, 3, -1, 4, 2, -2, -2, -1, 3, 7),
       array<i32, 12>(3, 4, -1, 2, 0, 5, -1, -3, -2, -4, 2, 5),
       array<i32, 12>(-8, -13, -15, -12, 0, -8, 2, 5, 2, 4, -13, -6),
       array<i32, 12>(6, 9, 10, 1, -4, 1, -3, 11, -2, -1, 5, -1),
       array<i32, 12>(1, 2, 2, -1, -12, 4, 0, 10, 1, 3, 3, 3),
       array<i32, 12>(-4, -6, -5, 13, 10, -2, 10, -2, 11, -4, 4, -8),
       array<i32, 12>(-4, -6, -6, -5, 8, -18, 3, 8, -7, 18, -16, -3),
       array<i32, 12>(-2, -3, -4, -9, -15, -6, 0, -1, 12, 4, -8, -3),
       array<i32, 12>(1, 1, 1, -11, -6, 5, -4, 2, 2, 3, 0, -3),
       array<i32, 12>(0, 0, 0, -1, 11, 0, 1, 6, 2, -8, 12, -4),
       array<i32, 12>(5, 8, 9, 11, 6, 8, -9, -3, -1, -10, 5, -4)
    );

    var bias = array<i32, 12>(-18, -9, -6, -1, -8, 9, 0, -4, 9, -7, 2, 9);

    var x = _x;
    var y = _y;

    var result: array<f32, 12>;
    var features: array<f32, 48>;

    for (var i = 0; i < 12; i = i + 1) {
        features[i] = x[i];
        features[i + 12] = y[i];
        features[i + 24] = abs(x[i]);
        features[i + 36] = abs(y[i]);
    }

    for (var i = 0; i < 12; i = i + 1) {
      var s: f32 = 0.0;
      for (var j = 0; j < 48; j = j + 1) {
        s += features[j] * f32(weights[j][i]);
      }

      result[i] = (s + f32(bias[i])) / 500.0;
    }

    return result;
  }

fn update(band: u32, y: array<float4,6>) -> float4 {
  //#define M mat4x4<f32>
//   #define F(i,_a,_b) {M a=_a,b=_b; float4 yi=y[i]; dx+=G(0)+G(1)+G(2)+G(3);}
  //#define G(i) yi[i]*((yi[i]>0.0)?a[i]:b[i])
//   #define G(i) (yi[i]*a[i]+abs(yi[i])*b[i])
  var dx = float4(0.0);
  if (band == 0u) { dx = f4(17,3,-17,15);
    dx = dx + F(y[0], M(-32,13,-9,20,-3,-58,6,27,2,21,-39,-5,-10,-9,4,-41), M(11,14,2,-34,-1,6,51,-26,-9,-41,-15,-19,9,14,9,-3));
    dx = dx + F(y[1], M(6,-1,-5,4,-5,4,-1,5,-12,13,15,26,0,4,0,0), M(-16,-8,-10,4,1,13,18,-3,-6,-2,-2,3,14,-9,-7,-19));
    dx = dx + F(y[2], M(-3,8,7,7,12,-4,-7,-11,2,-2,-5,1,-2,-2,-2,0), M(-7,-12,-8,0,-11,2,4,12,-17,2,21,10,12,3,4,-10));
    dx = dx + F(y[3], M(23,4,-1,6,-24,11,0,4,7,-1,14,0,-4,8,-4,40), M(2,-1,0,-7,-3,2,0,2,2,1,0,10,11,10,10,-10));
    dx = dx + F(y[4], M(-12,-17,-14,-13,6,7,7,-1,19,17,10,14,4,11,8,10), M(-4,-7,-8,3,-4,6,6,-1,3,0,-6,7,-3,-1,0,-5));
    dx = dx + F(y[5], M(10,14,12,13,-9,-16,-13,-12,5,3,5,-9,-9,-15,-16,6), M(-1,-1,1,-3,-12,-8,-7,6,-13,0,3,0,4,4,5,5));
  } else if (band == 1u) { dx = f4(12,0,-2,-7);
    dx = dx + F(y[0], M(-10,15,11,-2,6,21,-1,12,18,9,-10,16,-27,-12,-3,19), M(-13,16,-21,4,-5,-23,-3,5,-13,-38,-6,19,2,23,2,9));
    dx = dx + F(y[1], M(-81,11,10,11,-6,-70,2,11,21,12,-52,-2,24,-7,-10,-68), M(0,1,-6,-7,20,3,24,15,-12,-6,-4,0,15,-10,-16,8));
    dx = dx + F(y[2], M(-3,7,-7,5,12,0,18,0,-7,-12,2,-6,-8,15,2,-6), M(10,-4,29,-2,8,0,13,1,-5,14,12,-5,-15,16,-26,1));
    dx = dx + F(y[3], M(-2,4,4,2,4,4,3,2,7,-1,-3,5,0,2,16,4), M(0,-3,-2,-1,4,-1,2,1,1,3,1,2,-3,-5,-3,3));
    dx = dx + F(y[4], M(-21,-5,-19,-13,-1,-24,8,2,-10,11,33,-1,-9,2,-1,7), M(2,2,1,-2,-3,-3,17,24,-4,-2,2,-2,10,-6,1,-6));
    dx = dx + F(y[5], M(2,10,2,2,-12,2,-18,-8,5,-6,3,7,-8,-7,0,0), M(-1,-1,3,1,-5,0,-9,-1,-7,8,-2,-4,-3,4,-1,-4));
  } else { dx = f4(-18,9,-2,27);
    dx = dx + F(y[0], M(22,-20,17,19,13,-14,-9,7,-4,-4,-15,-2,-4,9,-16,19), M(0,-28,-6,-12,23,-30,-3,5,-3,37,41,-2,16,-6,-21,3));
    dx = dx + F(y[1], M(-4,-1,-2,-3,3,-8,-1,-14,-6,-15,-11,10,1,-11,-15,-2), M(-9,1,-1,-16,3,11,-4,1,9,-2,-21,-11,0,-8,17,11));

    dx = dx + F(y[2], M(-63,26,2,10,-22,-56,7,4,3,-8,-60,6,0,-2,-2,-66), M(-2,-17,-9,-20,-6,-3,-16,-13,-26,-25,-9,7,23,-9,0,-7));
    dx = dx + F(y[3], M(7,1,2,5,3,3,-4,5,-1,0,-9,-2,9,18,-1,0), M(1,0,1,2,0,3,1,2,-4,-1,-5,-1,4,0,-4,2));
    dx = dx + F(y[4], M(-7,3,16,-12,4,6,-8,4,7,1,-11,10,11,2,-10,12), M(-6,1,4,-9,-2,6,-4,1,15,5,6,5,-1,2,0,-3));
    dx = dx + F(y[5], M(24,7,-6,-3,-12,-30,10,0,-4,1,4,14,-6,4,4,-31), M(-7,4,0,10,16,4,1,-8,-7,-3,-10,-6,15,5,4,3));
  }
  return dx/500.0;
}


@compute @workgroup_size(16, 16)
fn main_image(@builtin(global_invocation_id) id: uint3) {
    let screen_size = uint2(textureDimensions(screen));
    if (id.x >= screen_size.x || id.y >= screen_size.y) { return; }

    current_index = int2(int(id.x), int(id.y));

    if (time.frame == 0u) {
        for (var i = 0u; i < NUM_CHANNELS / 4u; i = i+1u) {
            let noise = hash43(float3(f32(id.x + i * u32(SCREEN_WIDTH)), f32(id.y), 0.0)) - 0.5;

            data_buffer[data_buffer_idx(id.x, id.y, i * 4u +0u)] = noise.x;
            data_buffer[data_buffer_idx(id.x, id.y, i * 4u + 1u)] = noise.y;
            data_buffer[data_buffer_idx(id.x, id.y, i * 4u + 2u)] = noise.z;
            data_buffer[data_buffer_idx(id.x, id.y, i * 4u + 3u)] = noise.w;
        }
    }

    // 2
    let vert_sobel = R(-1, 1, 8) + R(-1, 0, 8)*2.0 + R(-1,-1, 8)
                    -R( 1, 1, 8) - R( 1, 0, 8)*2.0 - R( 1,-1, 8);
    // 1
    let hor_sobel = R( 1, 1, 4)+R( 0, 1, 4)*2.0+R(-1, 1, 4)
                   -R( 1,-1, 4)-R( 0,-1, 4)*2.0-R(-1,-1, 4);

    // 0
    var lap = R(1,1, 0)+R(1,-1, 0)+R(-1,1, 0)+R(-1,-1, 0)
              +2.0*(R(0,1, 0)+R(0,-1, 0)+R(1,0, 0)+R(-1,0, 0))- 12.0*R(0, 0, 0);

    var xs = data_buffer_read_12(id.x, id.y);

    var ys = array<f32, 12>(
        lap.x,
        lap.y,
        lap.z,
        lap.w,
        hor_sobel.x,
        hor_sobel.y,
        hor_sobel.z,
        hor_sobel.w,
        vert_sobel.x,
        vert_sobel.y,
        vert_sobel.z,
        vert_sobel.w,
    );

    let clamp_low = -1.5;
    let clamp_high = 1.5;

    var u = updaten(xs, ys);

     for (var i = 0; i < 12; i = i + 1) {
        xs[i] = clamp(xs[i] + u[i], clamp_low, clamp_high);
     }

    data_buffer_write_12(id.x, id.y, xs);

    let dx0 = float4(
        clamp(xs[0] + 0.5, 0.0, 1.0),
        clamp(xs[1] + 0.5, 0.0, 1.0),
        clamp(xs[2] + 0.5, 0.0, 1.0),
        clamp(xs[3] + 0.5, 0.0, 1.0)
    );

    textureStore(
        screen,
        int2(id.xy),
        dx0
    );
}
