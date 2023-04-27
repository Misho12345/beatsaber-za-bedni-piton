import moderngl_window as mglw
import moderngl_window.geometry
from math import *
import win32api

cam_rot = [0, 0]
cam_pos = [-3, 5, 0]

SPEED = 0.5
SENSITIVITY = 1.5


def add(v1: list, v2: list) -> list:
    return [v1[i] + v2[i] for i in range(len(v1))]


def mul(v: list, n: int) -> list:
    return [x * n for x in v]


def normalize(v: list) -> list:
    magnitude = sqrt(sum([x ** 2 for x in v]))
    if magnitude == 0:
        return v
    return [x / magnitude for x in v]


class App(mglw.WindowConfig):
    title = "Ray Marching"
    cursor = False
    # fullscreen = True

    resource_dir = 'programs'

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.window_size = win32api.GetSystemMetrics(0), win32api.GetSystemMetrics(1)
        print(self.window_size)

        self.quad = mglw.geometry.quad_fs()
        self.program = self.load_program(vertex_shader='vertex.glsl', fragment_shader='fragment.glsl')

        self.w_pressed = False
        self.a_pressed = False
        self.s_pressed = False
        self.d_pressed = False

        # self.texture1 = self.load_texture_2d('../textures/test.png')

        self.program['u_camPos'] = cam_pos
        self.program['u_camRot'] = cam_rot
        self.program['u_resolution'] = self.window_size
        # self.program['u_texture1'] = 1

    def render(self, time, frame_time):
        self.mouse_move()
        velocity = [0, 0, 0]

        if self.w_pressed:
            velocity[0] += 1
        if self.a_pressed:
            velocity[2] -= 1
        if self.s_pressed:
            velocity[0] -= 1
        if self.d_pressed:
            velocity[2] += 1

        if velocity != [0, 0, 0]:
            velocity = normalize(velocity)

            forward = normalize([cos(cam_rot[0]), 0, sin(cam_rot[0])])
            right = [forward[2], 0, -forward[0]]
            velocity = add(mul(right, velocity[2]), mul(forward, velocity[0]))
            cam_pos[0] += velocity[0] * SPEED
            cam_pos[2] += velocity[2] * SPEED

        self.ctx.clear()
        self.program['u_camRot'] = cam_rot
        self.program['u_camPos'] = cam_pos
        self.program['u_time'] = time
        # self.texture1.use(location=1)
        self.quad.render(self.program)

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

        if action == self.wnd.keys.ACTION_RELEASE:
            if key == self.wnd.keys.W:
                self.w_pressed = False
            if key == self.wnd.keys.A:
                self.a_pressed = False
            if key == self.wnd.keys.S:
                self.s_pressed = False
            if key == self.wnd.keys.D:
                self.d_pressed = False


if __name__ == '__main__':
    mglw.run_window_config(App)
