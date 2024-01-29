package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

Triangle :: distinct [3]rl.Vector2
Boid :: struct {
    tr: Triangle,
    pos: rl.Vector2,
    rot: f32,
    dir: rl.Vector2,
}

rotate_vec2 :: proc(vec: rl.Vector2, angle: f32) -> rl.Vector2 {
    angle_rad := angle*math.PI/180
    r := matrix[2, 2]f32 {
        math.cos(angle_rad), -math.sin(angle_rad),
        math.sin(angle_rad), math.cos(angle_rad),
    }
    xy := matrix[2, 1]f32 {vec.x, vec.y}
    t := r*xy
    return rl.Vector2 {t[0, 0], t[1, 0]}
}

rotate_triangle :: proc(tr: Triangle, angle: f32) -> Triangle {
    res := tr
    for i := 0; i < 3; i += 1 {
        res[i] = rotate_vec2(tr[i], angle)
    }
    return res
}

vec2_len :: proc(vec: rl.Vector2) -> f32 {
    return math.sqrt(vec.x*vec.x + vec.y*vec.y)
}

dot_prod :: proc(a: rl.Vector2, b: rl.Vector2) -> f32 {
    return a.x*b.x + a.y*b.y
}

draw_boid :: proc(boid: Boid) {
    boid := boid
    boid.tr = rotate_triangle(boid.tr, boid.rot)
    rl.DrawTriangle(boid.tr[0] + boid.pos, boid.tr[1] + boid.pos, boid.tr[2] + boid.pos, rl.SKYBLUE)
    rl.DrawLineV(boid.pos, boid.pos + boid.tr[1]*2, rl.RED)
}

move :: proc(boid: Boid, dir: rl.Vector2, delta: f32) -> Boid {
    boid := boid
    angle := math.acos(dot_prod(up, dir)/(vec2_len(up) * vec2_len(dir)))
    if dir.x < 0 {
        boid.rot = -angle*180/math.PI
    } else {
        boid.rot = angle*180/math.PI
    }
    boid.pos += dir*delta
    if boid.pos.x < 100 {
        boid.dir = normalize(lerp(boid.dir, right, delta*10))
    }
    if boid.pos.x > width-100 {
        boid.dir = normalize(lerp(boid.dir, left, delta*10))
    }
    if boid.pos.y < 100 {
        boid.dir = normalize(lerp(boid.dir, down, delta*10))
    }
    if boid.pos.y > height-100 {
        boid.dir = normalize(lerp(boid.dir, up, delta*10))
    }
    return boid
}

normalize :: proc(vec: rl.Vector2) -> rl.Vector2 {
    return vec/vec2_len(vec)
}

distance :: proc(a: rl.Vector2, b: rl.Vector2) -> f32 {
    return vec2_len(a-b)
}

lerp :: proc(a: rl.Vector2, b: rl.Vector2, t: f32) -> rl.Vector2 {
    return a + (b - a) * t
}

up :: rl.Vector2{0, -1}
down :: rl.Vector2{0, 1}
right :: rl.Vector2{1, 0}
left :: rl.Vector2{-1, 0}
width :: 1600
height :: 900
sep_radius :: 50
align_radius :: 150

main :: proc() {
    rl.InitWindow(width, height, "Boids")
    rl.SetTargetFPS(60)

    boids: [20]Boid
    for i := 0; i < len(boids); i += 1 {
        boids[i] = Boid {
            tr = Triangle {
                rl.Vector2{5, 5},
                rl.Vector2{0, -5},
                rl.Vector2{-5, 5}
            } * 2,
            pos = rl.Vector2{rand.float32()*width, rand.float32()*height},
            rot = 0,
            dir = normalize(rl.Vector2{rand.float32(), rand.float32()}),
        }
    }
    bg :: rl.Color {32, 32, 32, 255}
    speed :: 200
    pause := false
    for !rl.WindowShouldClose() {
        delta := rl.GetFrameTime()
        if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
            pause = !pause
        }
        rl.BeginDrawing()
        if !pause {
            rl.ClearBackground(bg)
            for i := 0; i < len(boids); i += 1 {
                a := boids[i]
                sep := a.dir
                align: rl.Vector2
                coh: rl.Vector2
                for j := 0; j < len(boids); j += 1 {
                    if i == j do continue
                    b := boids[j]
                    if distance(a.pos, b.pos) <= sep_radius {
                        sep += a.pos - b.pos
                    }
                    if distance(a.pos, b.pos) <= align_radius {
                        align += b.dir
                        if coh == {0, 0} {
                            coh = b.pos
                        } else {
                            coh = lerp(coh, b.pos, 0.5)
                        }
                    }
                }
                dir := lerp(sep, align, 0.1)
                dir = lerp(dir, (coh-a.pos), 0.1)
                dir = normalize(lerp(a.dir, normalize(dir), delta*6))
                boids[i].dir = dir
                boids[i] = move(boids[i], a.dir*speed, delta)
                if i == 0 {
                    rl.DrawCircleLinesV(a.pos, sep_radius, rl.RED)
                    rl.DrawCircleLinesV(a.pos, align_radius, rl.GREEN)
                    rl.DrawCircleV(coh, 5, rl.ORANGE)
                }
                draw_boid(boids[i])
            }
        }
        rl.EndDrawing()
    }
    rl.CloseWindow()
}
