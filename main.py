import moderngl_window as mglw
import moderngl_window.geometry
from math import *
from screeninfo import get_monitors
import win32api
import numpy as np
import struct

import sys
sys.path.append("modules")
swordPluged = 1
if swordPluged:
    from swordRotation import *

cam_rot = [0, 0]
cam_pos = [0, 150, 0]
prev_cam_pos = []

sword_rot = [0, 1, 1]
sword_pos = [0, 80, 0]

SPEED = 1
SENSITIVITY = 1.5

monitor = get_monitors()[0]


def add(v1: list, v2: list) -> list:
    return [v1[i] + v2[i] for i in range(len(v1))]


def mul(v: list, n: float) -> list:
    return [x * n for x in v]


def normalize(v: list) -> list:
    magnitude = sqrt(sum([x ** 2 for x in v]))
    if magnitude == 0:
        return v
    return [x / magnitude for x in v]


def dot(vec1, vec2):
    result = 0.0
    for i in range(len(vec1)):
        result += vec1[i] * vec2[i]
    return result


class App(mglw.WindowConfig):
    title = "Ray Marching"
    cursor = False
    fullscreen = True
    window_size = monitor.width, monitor.height
    resource_dir = 'programs'

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.quad = mglw.geometry.quad_fs()
        self.program = self.load_program(vertex_shader='vertex.glsl', fragment_shader='fragment.glsl')

        self.w_pressed = False
        self.a_pressed = False
        self.s_pressed = False
        self.d_pressed = False
        self.space_pressed = False

        self.texture0 = self.load_texture_2d('../textures/ground.jpg')
        self.texture1 = self.load_texture_2d('../textures/grass.jpg')

        self.texture0.build_mipmaps()
        self.texture1.build_mipmaps()

        self.program['u_texture0'] = 0
        self.program['u_texture1'] = 1

        self.program['u_camPos'] = cam_pos
        self.program['u_camRot'] = cam_rot

        self.program['u_swordPos'] = sword_pos
        self.program['u_swordRot'] = sword_rot

        self.program['u_resolution'] = self.window_size

        with open("programs/compute_floor.glsl") as f:
            self.compute_shader = self.ctx.compute_shader(f.read())

        self.input_buffer = self.ctx.buffer(np.array([cam_pos[::2]], dtype="f4").tobytes(), dynamic=True)
        self.height_buffer = self.ctx.buffer(np.array([0], dtype="f4").tobytes(), dynamic=True)
        self.normal_buffer = self.ctx.buffer(np.array([0, 0, 0], dtype="f4").tobytes(), dynamic=True)

        self.input_buffer.bind_to_storage_buffer(0)
        self.height_buffer.bind_to_storage_buffer(1)
        self.normal_buffer.bind_to_storage_buffer(2)

        self.on_ground = True
        self.g_force = 0
        self.g_velocity = 0

        self.ground_height = 0
        self.ground_normal = []

    def render(self, time, frame_time):
        if prev_cam_pos != cam_pos:
            prev_cam_pos.clear()
            prev_cam_pos.extend(cam_pos)

            self.get_ground_height()
            cam_pos[1] = max(cam_pos[1], self.ground_height)

        self.update_player_y(frame_time)
        if swordPluged:
            rotateSword(sword_rot)
            # sword_rot[:]=rotateSword()
        self.mouse_move()
        self.player_move(frame_time)

        self.ctx.clear()
        self.program['u_camRot'] = cam_rot
        self.program['u_camPos'] = cam_pos

        self.program['u_swordPos'] = sword_pos
        self.program['u_swordRot'] = sword_rot

        self.program['u_time'] = time

        self.texture0.use(location=0)
        self.texture1.use(location=1)

        self.quad.render(self.program)

    def get_ground_height(self):
        self.height_buffer.clear()

        self.input_buffer.write(np.array([cam_pos[::2]], dtype="f4").tobytes())
        self.compute_shader.run(1, 1, 1)

        self.ground_height = struct.unpack('<f', self.height_buffer.read())[0] + 5
        self.ground_normal.clear()
        self.ground_normal.extend(struct.unpack('<3f', self.normal_buffer.read()))

    def mouse_move(self):
        cursor = win32api.GetCursorPos()
        center = self.wnd.width // 2, self.wnd.height // 2
        win32api.SetCursorPos(center)

        dx = (center[0] - cursor[0]) / self.wnd.width
        dy = (center[1] - cursor[1]) / self.wnd.height

        cam_rot[0] += atan(dx) * SENSITIVITY / pi
        cam_rot[1] += atan(dy) * SENSITIVITY / pi

        if cam_rot[1] > pi / 2.1:
            cam_rot[1] = pi / 2.1
        if cam_rot[1] < -pi / 2.1:
            cam_rot[1] = -pi / 2.1

    def player_move(self, frame_time):
        velocity = [0, 0, 0]

        if self.w_pressed:
            velocity[0] += 1
        if self.a_pressed:
            velocity[2] -= 1
        if self.s_pressed:
            velocity[0] -= 1
        if self.d_pressed:
            velocity[2] += 1

        if self.space_pressed and self.on_ground:
            self.g_velocity = -1

        if velocity != [0, 0, 0]:
            forward = normalize([cos(cam_rot[0]), 0, sin(cam_rot[0])])
            right = [forward[2], 0, -forward[0]]

            velocity = normalize(velocity)
            velocity = add(mul(right, velocity[2]), mul(forward, velocity[0]))

            speed_factor = 0.8
            if self.on_ground:
                dot_product = dot(velocity, self.ground_normal)
                angle = acos(dot_product)
                speed_factor = min(angle / pi * 2, 1)

            cam_pos[0] += velocity[0] * SPEED * speed_factor * frame_time * 20
            cam_pos[2] += velocity[2] * SPEED * speed_factor * frame_time * 20

    def update_player_y(self, frame_time):
        self.g_force += 5 * frame_time
        self.g_velocity += self.g_force * frame_time
        cam_pos[1] -= self.g_velocity

        if cam_pos[1] < self.ground_height:
            cam_pos[1] = self.ground_height
            self.g_force = 0
            self.g_velocity = 0
            self.on_ground = True
        else:
            self.on_ground = cam_pos[1] == self.ground_height

    def key_event(self, key, action, modifiers):
        if action == self.wnd.keys.ACTION_PRESS:
            if key == self.wnd.keys.W:
                self.w_pressed = True
            if key == self.wnd.keys.A:
                self.a_pressed = True
            if key == self.wnd.keys.S:
                self.s_pressed = True
            if key == self.wnd.keys.D:
                self.d_pressed = True

            if key == self.wnd.keys.SPACE:
                self.space_pressed = True

        if action == self.wnd.keys.ACTION_RELEASE:
            if key == self.wnd.keys.W:
                self.w_pressed = False
            if key == self.wnd.keys.A:
                self.a_pressed = False
            if key == self.wnd.keys.S:
                self.s_pressed = False
            if key == self.wnd.keys.D:
                self.d_pressed = False

            if key == self.wnd.keys.SPACE:
                self.space_pressed = False


if __name__ == '__main__':
    mglw.run_window_config(App)
