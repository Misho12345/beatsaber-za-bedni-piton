import moderngl_window as mglw
import moderngl_window.geometry
from math import *
from screeninfo import get_monitors
import win32api

# a= 'Ax:+0.11Ay:-0.03Az:+0.92Gx:+0.03Gy:+0.00Gz:+0.02'
# print(len(a))
# import serial
# serialcomm = serial.Serial('COM5', 38400,timeout=0.05)
# serialcomm.timeout = 1
# j = 0
# def decodeInfo(string):
#     result = ['','','','','','']
#     if len(a)==50:
#         o=0
#         i=3
#         while i<len(a):
#             for j in range(5):
#                 result[o]+=string[i+j]
#             o+=1
#             i+=8
#         for i in range(len(result)):
#             result[i]=float(result[i])
#     return result
# def give3DVecFromSerialString(string):
#     axes = decodeInfo(string)
# import math
# from typing import List
#
# def get_orientation(sensor_data: List[float]):
#     # Extract accelerometer and gyroscope data from sensor_data
#     ax, ay, az, gx, gy, gz = sensor_data
#
#     # Calculate pitch and roll angles using accelerometer data
#     pitch = math.atan2(ax, math.sqrt(ay ** 2 + az ** 2))
#     roll = math.atan2(ay, math.sqrt(ax ** 2 + az ** 2))
#
#     # Calculate yaw angle using gyroscope data
#     dt = 0.01  # time step in seconds
#     yaw = 0
#     for gyro in [gx, gy, gz]:
#         yaw += gyro * dt
#     yaw = math.radians(yaw)
#
#     # Calculate the magnitude of the acceleration vector
#     acc_magnitude = math.sqrt(ax ** 2 + ay ** 2 + az ** 2)
#
#     # Normalize the acceleration vector
#     if acc_magnitude != 0:
#         ax /= acc_magnitude
#         ay /= acc_magnitude
#         az /= acc_magnitude
#
#     # Convert pitch, roll, and yaw angles to a Vector3
#     x = math.cos(yaw) * math.cos(roll)
#     y = math.sin(yaw) * math.cos(roll)
#     z = math.sin(roll)
#
#     return [x,y,z]
# print(decodeInfo(a))
# j=0
# while j<50:
#     a = serialcomm.readline().decode('utf8', 'ignore')
#     if(len(a)==50):
#         b = decodeInfo(a)
#         print(b,a)
#         sensor_data = b  # example sensor data
#         orientation = get_orientation(sensor_data)
#         print(orientation)  # prints "Vector3(0.0053, -0.0499, 0.9987)"
#     else:
#         print(len(a),a)
#     j=j+1

cam_rot = [0, 0]
cam_pos = [-3, 10, 0]

sword_rot = [0, 0, 1]
sword_pos = [0, 0, 0]

SPEED = 0.5
SENSITIVITY = 1.5

monitor = get_monitors()[0]


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
    fullscreen = True
    window_size = monitor.width, monitor.height
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

        # self.texture0 = self.load_texture_2d('../textures/ground.jpg')
        # self.texture1 = self.load_texture_2d('../textures/grass.jpg')
        #
        # self.program['u_texture0'] = 0
        # self.program['u_texture1'] = 1

        self.program['u_camPos'] = cam_pos
        self.program['u_camRot'] = cam_rot

        self.program['u_swordPos'] = sword_pos
        self.program['u_swordRot'] = sword_rot

        self.program['u_resolution'] = self.window_size

    def render(self, time, frame_time):
        sword_rot[0] = cos(time)
        sword_rot[2] = sin(time)

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
            forward = normalize([cos(cam_rot[0]), 0, sin(cam_rot[0])])
            right = [forward[2], 0, -forward[0]]

            velocity = normalize(velocity)
            velocity = add(mul(right, velocity[2]), mul(forward, velocity[0]))

            cam_pos[0] += velocity[0] * SPEED
            cam_pos[2] += velocity[2] * SPEED

        self.ctx.clear()
        self.program['u_camRot'] = cam_rot
        self.program['u_camPos'] = cam_pos

        self.program['u_swordPos'] = sword_pos
        self.program['u_swordRot'] = sword_rot

        self.program['u_time'] = time

        # self.texture0.use(location=0)
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
