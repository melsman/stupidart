import "lib/github.com/diku-dk/lys/lys"
import "lib/github.com/diku-dk/lys/lys_core_entries"

import "base"
import "shapegen"

module rectangle = mk_full_shape (import "shapes/rectangle")
module circle = mk_full_shape (import "shapes/circle")
module triangle = mk_full_shape (import "shapes/triangle")

let same_dims_2d 'a [m][n][m1][n1] (_source: [m][n]a) (target: [m1][n1]a): [m][n]a =
  target :> [m][n]a


module lys_core = {
  type sized_state [h][w] = {rng: rng, paused: bool, score: f32,
                             shape: #triangle | #circle | #rectangle,
                             image_source: [h][w]argb.colour,
                             image_approx: [h][w]argb.colour}
  type~ state = sized_state [][]

  entry init [h][w] (seed: i32) (image_source: [h][w]i32): state =
    let rng = rnge.rng_from_seed [seed]
    let image_approx = replicate h (replicate w 0)
    let score = reduce_comm (+) 0 (map r32 (flatten (map2 (map2 (color_diff)) image_approx image_source)))
    in {rng, paused=false, score, shape=#triangle, image_source, image_approx}

  entry score (s: state): f32 = s.score

  let keydown (key: i32) (s: state) =
    if key == SDLK_SPACE then s with paused = !s.paused
    else if key == SDLK_1 then s with shape = #triangle
    else if key == SDLK_2 then s with shape = #circle
    else if key == SDLK_3 then s with shape = #rectangle
    else s

  let event (e: event) (s: state): state =
    match e
    case #step _td ->
      if s.paused then s
      else let image_approx = same_dims_2d s.image_source s.image_approx
           let (image_approx', improved, rng') =
             match s.shape
             case #triangle ->   triangle.add s.image_source image_approx s.rng
             case #circle ->       circle.add s.image_source image_approx s.rng
             case #rectangle -> rectangle.add s.image_source image_approx s.rng
           in s with image_approx = image_approx'
                with score = s.score - improved
                with rng = rng'
    case #keydown {key} -> keydown key s
    case _ -> s

  let render (s: state): [][]i32 = s.image_approx

  let resize _ _ (s: state): state = s
}

open lys_core
open lys_core_entries lys_core