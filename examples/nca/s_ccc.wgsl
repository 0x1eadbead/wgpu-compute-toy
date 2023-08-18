const N = 12u;
const S = 5000.;
const B = array<i32, 12> (-108,-74,-104,-20,4,60,2,52,-66,26,-69,-134);
const W = array<array<i32, 12>, 48>(
        array<i32, 12>(-221,-46,-28,54,21,33,-12,-30,-32,-23,25,-43),         array<i32, 12>(85,-217,39,-41,-4,57,47,156,-38,-14,4,-123),         array<i32, 12>(12,-13,-207,-1,-36,38,-32,-20,21,-6,29,70),         array<i32, 12>(-35,-23,6,-225,-5,24,-32,-28,57,2,-5,28),         array<i32, 12>(-15,-9,-9,82,-250,4,27,34,-18,33,62,4),         array<i32, 12>(-22,-52,-53,-43,-38,-260,-30,-34,32,50,-14,-62),         array<i32, 12>(14,-26,18,13,-61,55,-274,-35,46,-41,-39,27),         array<i32, 12>(7,-23,-14,50,1,-20,-17,-319,-23,-32,-77,-46),         array<i32, 12>(11,-11,-10,20,4,-50,18,51,-339,46,49,44),         array<i32, 12>(4,-33,-10,-39,-21,7,-75,-36,110,-325,-44,95),         array<i32, 12>(-2,-12,-4,-11,-5,-23,38,78,28,3,-276,-38),         array<i32, 12>(39,26,16,-3,84,34,61,-10,-65,13,84,-223),         array<i32, 12>(164,-5,85,-22,-19,14,12,15,8,-8,22,12),         array<i32, 12>(-24,63,-70,-8,11,6,-8,-8,6,-24,-7,5),         array<i32, 12>(-110,-54,121,72,4,-9,21,12,-12,0,10,0),         array<i32, 12>(34,42,-26,158,40,-18,-1,-3,67,-27,-27,-13),         array<i32, 12>(-25,-41,-7,-21,-42,28,17,-28,-13,11,-25,-2),         array<i32, 12>(32,57,17,38,32,40,-52,18,-17,-10,34,25),         array<i32, 12>(31,56,-2,72,-3,-54,-113,-23,-4,-48,7,8),         array<i32, 12>(-25,-38,2,-47,-3,13,-1,152,3,12,25,-2),         array<i32, 12>(-72,-112,-28,-49,27,39,-9,-26,-123,99,3,84),         array<i32, 12>(11,-4,-18,66,28,-26,27,-33,79,51,-97,-36),         array<i32, 12>(63,79,25,53,-16,-6,-44,1,13,-118,-26,-3),         array<i32, 12>(27,104,35,-12,19,12,-23,21,82,-78,47,172),         array<i32, 12>(89,-37,-53,-17,16,28,-27,7,82,51,-12,-2),         array<i32, 12>(2,-88,-65,177,12,-25,39,-88,109,-48,77,299),         array<i32, 12>(-27,-24,108,-28,9,-27,-21,-63,-19,46,-15,-73),         array<i32, 12>(-16,8,16,-24,-10,19,-20,-19,25,-5,-4,-8),         array<i32, 12>(-7,2,3,9,-16,22,17,-1,39,26,9,16),         array<i32, 12>(-13,-2,-12,7,-20,-27,-11,-49,25,-12,16,3),         array<i32, 12>(-2,-13,5,-35,-22,0,3,11,-3,21,-7,-8),         array<i32, 12>(-3,14,16,-21,12,-17,-18,-25,60,-22,-57,-35),         array<i32, 12>(-19,-11,-9,7,5,-13,14,3,-54,45,55,40),         array<i32, 12>(3,-26,3,9,13,-5,-1,-3,8,-101,15,22),         array<i32, 12>(-12,-47,-31,-37,6,14,-35,-7,97,20,-45,-130),         array<i32, 12>(31,85,37,-50,30,-7,-8,15,136,-14,-40,-64),         array<i32, 12>(-5,-3,-2,-10,6,-12,-8,1,28,-15,-19,-11),         array<i32, 12>(8,10,1,1,5,8,-25,-6,32,-41,-7,3),         array<i32, 12>(-10,21,11,5,-6,-16,-5,18,-7,8,19,-6),         array<i32, 12>(-14,-92,-42,-1,5,24,-10,-19,38,-14,-19,35),         array<i32, 12>(4,12,4,-14,11,-20,-3,36,-52,33,43,14),         array<i32, 12>(3,1,8,-4,-18,9,28,15,-3,-6,11,10),         array<i32, 12>(-16,-28,-6,-17,-1,-10,9,17,-9,11,4,6),         array<i32, 12>(-1,67,35,-10,-58,40,91,31,18,-18,-7,2),         array<i32, 12>(-3,-56,-21,25,11,23,-13,-24,17,4,7,16),         array<i32, 12>(10,-45,-17,33,20,10,-18,-20,-57,58,-15,-26),         array<i32, 12>(15,22,20,25,-9,11,25,1,-27,-6,14,1),         array<i32, 12>(43,136,45,33,-9,-63,30,-26,-187,76,114,38), );


#storage states array<array<f32,N>>
var<private> current_index: int2;

const SW = 400 ;
const SH = 300 ;

fn R(dx: i32, dy: i32, c: u32) -> f32 {
    let x = (current_index.x + dx + SW) % SW;
    let y = (current_index.y + dy + SH) % SH;
    let i = x + y*SW;
    return states[i][c];
}

fn sobx(c: u32) -> f32 {
    return R(-1, 1, c) + R(-1, 0, c)*2.0 + R(-1,-1, c)
          -R( 1, 1, c) - R( 1, 0, c)*2.0 - R( 1,-1, c);
}

fn soby(c: u32) -> f32 {
    return R( 1, 1, c)+R( 0, 1, c)*2.0+R(-1, 1, c)
          -R( 1,-1, c)-R( 0,-1, c)*2.0-R(-1,-1, c);
}


fn lap(c: u32) -> f32 {
    return R(1,1,c)+R(1,-1,c)+R(-1,1,c)+R(-1,-1,c) 
        +2.0* ( R(0,1,c)+R(0,-1,c)+R(1,0,c)+R(-1,0,c) ) - 12.0*R(0, 0,c);
}

fn update(ys: array<f32, N>, ps: array<f32, N>) -> array<f32, N> {
  // for some reason, accessing consts is very expensive, hence local vars
  var ws = W;
  var bs = B;

  var ys_v = ys;
  var ps_v = ps; // vulkan target in naga does not allow indexing an argument array

  // construct hidden state
  var hs = array<f32, 48>();
  for (var i = 0u; i<N; i++) {
    hs[i] = ys_v[i];
    hs[i+N] = ps_v[i];
    hs[i+N*2u] = abs(ys_v[i]);
    hs[i+N*3u] = abs(ps_v[i]);
  }

  // do 1x1 conv
  var dy = array<f32, N>();
  for (var c = 0u; c < N; c++) {
      var us = f32(bs[c]);

      for (var i = 0u; i < 48u; i++) {
          us += hs[i] * f32(ws[i][c]);
      }
      dy[c] = us / S;
  }

  return dy;
}

fn get_index(idx : u32, idy: u32, screen_size: uint2) -> u32 {
    return  idx + idy * u32(SW);
}


@compute @workgroup_size(16, 16)
fn main_image(@builtin(global_invocation_id) id: uint3) {
    // setup
    let screen_size = uint2(textureDimensions(screen));
    if (id.x < u32(SW) && id.y < u32(SH)) { 
    current_index = int2(int(id.x), int(id.y));

    // initial state
    if (time.frame == 0u) {
        for (var s=0u; s<N; s++) {
            // let i = id.x + id.y * SW;
            let i = get_index(id.x, id.y, screen_size);
            let rand = fract(sin(f32(i + N * s) / f32(SW)) * 43758.5453123) + .5;
            states[i][s] = floor(rand);
        }

    return;
    }


    // construct state + perception vectors
    var xs = array<f32, N>();
    for (var c=0u; c<N; c++) {
        // let i = id.x + id.y * SW;
        let i = get_index(id.x, id.y, screen_size);
        xs[c] = states[i][c];
    }

    var ps = array<f32, N>(
        lap(0u),
        lap(1u),
        lap(2u),
        lap(3u),

        sobx(4u),
        sobx(5u),
        sobx(6u),
        sobx(7u),

        soby(8u),
        soby(9u),
        soby(10u),
        soby(11u)
    );
   
    // update state
    var dx = update(xs, ps);

    // save state
    for (var s=0u; s<N; s++) {
        // let i = id.x + id.y * SW;
        let i = get_index(id.x, id.y, screen_size);
        states[i][s] += dx[s];
    }
    }

    // display rgba channels 
    // let i = id.x + id.y * SW;

    // resize texture to the screen size: id / size(tex) * screen_size
    var idxs = u32(f32(id.x) / f32(screen_size.x) * f32(SW) + 30.);
    var idys = u32(f32(id.y) / f32(screen_size.y) * f32(SH) );
    
    let i = get_index(idxs, idys, screen_size);
    var xrgb = vec4(states[i][0], states[i][1], states[i][2], states[i][3]) ;
    xrgb *= 2.;
    

    textureStore(
        screen,
        int2(id.xy),
        xrgb
    );
}


