const N = 12u;
const S = 5000.;
const B = array<i32, 12> (37,-141,-95,49,-67,-95,-51,-85,-74,-79,-10,136);
const W = array<array<i32, 12>, 48>(
        array<i32, 12>(-341,-27,72,-301,85,-166,-104,-73,9,22,107,14),         array<i32, 12>(-31,-294,-4,131,38,-65,-99,-43,94,-57,12,-40),         array<i32, 12>(-14,-34,-567,-239,90,2,-135,-152,159,-160,96,-117),         array<i32, 12>(44,-97,20,-422,71,59,294,55,-190,78,-115,151),         array<i32, 12>(-14,-6,-9,-113,-731,-164,-43,14,80,-57,26,-46),         array<i32, 12>(-38,4,-40,-21,3,-581,200,-49,134,-109,-109,143),         array<i32, 12>(-84,35,-36,44,5,15,-553,77,73,51,-39,-40),         array<i32, 12>(-3,41,32,-77,-119,292,-11,-612,242,-70,-60,21),         array<i32, 12>(3,-14,-45,226,-136,10,26,-137,-629,-20,21,-29),         array<i32, 12>(-32,24,15,18,47,56,27,80,50,-586,-11,13),         array<i32, 12>(-58,-61,-57,-40,-8,143,101,68,-22,-94,-625,-49),         array<i32, 12>(-59,-105,-2,-54,-33,-139,11,-73,-102,35,-134,-681),         array<i32, 12>(48,-17,-36,-57,9,-14,-13,4,24,1,7,-4),         array<i32, 12>(-295,302,-155,-142,-300,-33,18,44,79,-14,140,-163),         array<i32, 12>(66,29,268,60,36,-87,-53,-74,6,15,28,-30),         array<i32, 12>(-331,46,-186,292,-41,-19,-2,-132,77,228,25,-61),         array<i32, 12>(-103,12,-69,-39,-341,6,39,14,-36,-58,134,25),         array<i32, 12>(-87,-1,-58,92,-40,-182,16,141,-51,83,37,-37),         array<i32, 12>(32,-12,9,-38,22,-68,61,100,-18,-33,4,19),         array<i32, 12>(196,-20,96,-110,43,12,92,255,93,-125,-91,70),         array<i32, 12>(127,-17,77,-84,122,40,-15,49,-83,-63,-23,-16),         array<i32, 12>(182,-24,111,-191,-8,72,31,77,-51,-215,-13,10),         array<i32, 12>(-187,24,-95,97,-90,101,38,36,-56,-18,168,88),         array<i32, 12>(-106,9,-31,28,-32,-3,-71,-81,-6,25,78,-174),         array<i32, 12>(87,40,153,137,-189,57,-128,106,499,269,154,-446),         array<i32, 12>(-6,137,-70,-40,-5,-76,18,24,-71,56,29,49),         array<i32, 12>(-428,-204,123,-211,296,436,166,500,-173,-101,-191,4),         array<i32, 12>(157,-17,71,-41,-83,-141,-30,-15,112,-90,-122,-93),         array<i32, 12>(37,11,11,35,101,-39,120,-121,58,-25,-42,47),         array<i32, 12>(133,-4,49,25,-35,-78,-18,93,132,104,-56,-53),         array<i32, 12>(-145,20,-82,211,126,-52,118,0,-32,28,131,-188),         array<i32, 12>(-4,17,25,68,54,40,19,-221,-53,25,43,-46),         array<i32, 12>(-226,-42,-16,-103,-75,91,-125,30,-58,-52,220,-101),         array<i32, 12>(75,21,49,-35,28,-16,55,-100,70,-20,106,-19),         array<i32, 12>(-186,-22,-98,-3,-65,12,59,-99,-46,61,28,36),         array<i32, 12>(-193,-12,-87,-27,131,35,261,115,-74,-79,221,51),         array<i32, 12>(-16,9,-4,19,34,0,18,-16,-46,-12,-23,41),         array<i32, 12>(-46,-38,-42,14,102,-24,5,0,-2,43,43,61),         array<i32, 12>(-26,-32,-29,-4,-105,-21,-69,32,82,18,53,-84),         array<i32, 12>(42,11,20,-31,29,-3,10,40,21,-6,43,4),         array<i32, 12>(-22,-2,-22,-71,-82,48,-45,-6,34,-13,-225,81),         array<i32, 12>(-31,7,-20,25,-14,139,-8,-27,-55,-9,32,51),         array<i32, 12>(126,-1,75,-66,65,57,-49,-53,-16,-114,-30,-19),         array<i32, 12>(58,1,20,-3,11,-25,-29,120,101,12,-13,-21),         array<i32, 12>(66,24,53,43,30,36,-51,11,23,-63,113,-26),         array<i32, 12>(44,-5,29,-17,-36,-42,-7,-6,28,80,31,-34),         array<i32, 12>(48,-7,10,-8,42,-35,-28,31,-14,53,-49,-65),         array<i32, 12>(-87,-34,-61,-35,20,32,-8,83,-19,4,-158,27), );


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
    var idxs = u32(f32(id.x) / f32(screen_size.x) * f32(SW) );
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


