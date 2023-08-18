const N = 12u;
const S = 5000.;
const B = array<i32, 12> (-77,-179,-244,128,165,-59,-18,-60,-223,-66,267,188);
const W = array<array<i32, 12>, 48>(
        array<i32, 12>(-391,1,86,56,110,290,60,-6,-209,92,156,-76),         array<i32, 12>(-3,-407,14,178,-3,76,-81,-62,-59,-210,-10,182),         array<i32, 12>(28,56,-491,-48,45,361,-16,-63,-234,88,-9,-62),         array<i32, 12>(-64,-6,-17,-419,-200,83,126,-123,-90,-155,31,107),         array<i32, 12>(72,13,88,132,-736,-150,27,58,-48,-38,6,88),         array<i32, 12>(-37,-78,-82,161,142,-746,-101,185,-65,221,-16,-82),         array<i32, 12>(-71,59,-51,186,154,-145,-527,-212,133,186,-93,-15),         array<i32, 12>(-82,-69,-24,-327,57,-45,-182,-501,-95,-62,-26,-54),         array<i32, 12>(22,123,62,378,154,-53,-31,1,-724,-30,-78,-60),         array<i32, 12>(-93,17,-81,-122,-135,17,48,5,35,-790,-52,33),         array<i32, 12>(6,-143,180,-253,21,-175,-117,-117,27,25,-748,116),         array<i32, 12>(-57,75,-53,-8,-57,-17,23,93,93,-23,-146,-678),         array<i32, 12>(147,-16,-47,22,40,45,5,-77,-62,-8,-24,-61),         array<i32, 12>(-71,180,-72,122,-3,-22,22,-146,65,32,-43,195),         array<i32, 12>(-89,-14,127,50,-46,68,-30,4,-59,-24,80,5),         array<i32, 12>(-352,98,-346,598,-91,39,356,-336,265,42,-438,37),         array<i32, 12>(114,-116,104,-210,17,-95,-106,208,-88,-15,125,-119),         array<i32, 12>(44,-40,60,10,2,307,-152,-83,-46,104,110,-126),         array<i32, 12>(167,78,158,-206,-59,1,-368,86,-79,-193,305,73),         array<i32, 12>(7,263,-37,174,38,-232,130,-376,30,-21,52,292),         array<i32, 12>(-120,-140,-93,192,-111,33,104,9,52,-70,-234,-161),         array<i32, 12>(-201,85,-158,99,-67,-7,122,-13,89,229,-254,161),         array<i32, 12>(87,-62,92,-115,128,81,-30,91,-137,-146,104,-51),         array<i32, 12>(-17,174,-24,-46,-21,-80,25,-64,69,88,52,281),         array<i32, 12>(61,-60,148,112,-183,241,-101,89,89,14,-351,105),         array<i32, 12>(-12,16,23,-160,80,-140,67,-223,-150,-79,-74,-589),         array<i32, 12>(-281,-48,-49,-257,-291,-182,-283,124,253,138,-297,88),         array<i32, 12>(23,-46,48,-62,-42,1,-137,4,-4,1,-1,-71),         array<i32, 12>(100,47,136,93,102,392,-30,-156,-44,277,32,3),         array<i32, 12>(-143,-2,-92,-244,-57,16,291,119,10,-15,-55,69),         array<i32, 12>(-167,89,-163,26,15,-158,7,-14,69,151,-178,103),         array<i32, 12>(-25,35,-35,44,41,35,117,-30,29,121,-29,90),         array<i32, 12>(224,132,214,189,13,247,-3,-75,-141,-242,167,-71),         array<i32, 12>(13,-83,11,37,84,166,32,-35,-57,-265,56,-131),         array<i32, 12>(468,-130,445,348,62,274,125,-53,-221,129,56,36),         array<i32, 12>(-86,664,-89,-94,-161,-67,-22,353,36,-273,-37,293),         array<i32, 12>(13,22,19,48,13,-13,8,-43,-17,-29,8,-24),         array<i32, 12>(-17,11,-15,15,39,-28,-33,-9,22,23,-32,42),         array<i32, 12>(-16,-13,-26,-24,32,-16,-7,9,-40,-5,40,-2),         array<i32, 12>(-105,62,-87,-49,-95,-78,-92,-37,66,36,-74,43),         array<i32, 12>(53,-47,40,-20,41,-46,-24,31,-31,19,62,-54),         array<i32, 12>(86,-35,101,-93,33,46,-5,50,-148,-47,107,-46),         array<i32, 12>(122,-78,128,15,7,144,30,-10,-160,-64,90,-74),         array<i32, 12>(-58,182,-53,84,-104,94,47,-62,72,4,-64,192),         array<i32, 12>(-7,-47,-21,87,-40,4,73,-31,28,20,-39,-78),         array<i32, 12>(-79,-1,-85,-45,-7,-6,50,135,171,49,-41,21),         array<i32, 12>(-64,-41,-74,52,-54,-6,93,-15,140,48,-71,-70),         array<i32, 12>(-32,-124,-21,-43,15,-19,-53,45,56,18,-59,-165), );


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


