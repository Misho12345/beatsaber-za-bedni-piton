import moderngl_window as mglw
import moderngl_window.geometry
from math import *
from screeninfo import get_monitors
import win32api

import serial
serialcomm = serial.Serial('COM5', 38400,timeout=0.05)
serialcomm.timeout = 1
a= 'Ax:+1.04Ay:-0.03Az:-0.23Gx:+0.00Gy:+0.00Gz:+0.00'
lenOfOutputStr=48
def decodeInfo(string):
    result = ['','','','','','']
    if len(a)==lenOfOutputStr:
        o=0
        i=3
        while i<len(a):
            for j in range(5):
                result[o]+=string[i+j]
            o+=1
            i+=8
        for i in range(len(result)):
            result[i]=float(result[i])
    return result

from typing import List

def get_orientation(sensor_data: List[float]):
    # Extract accelerometer and gyroscope data from sensor_data
    ax, ay, az, gx, gy, gz = sensor_data

    # Calculate pitch and roll angles using accelerometer data
    pitch = atan2(ax, sqrt(ay ** 2 + az ** 2))
    roll = atan2(ay, sqrt(ax ** 2 + az ** 2))

    # Calculate yaw angle using gyroscope data
    dt = 0.01  # time step in seconds
    yaw = 0
    for gyro in [gx, gy, gz]:
        yaw += gyro * dt
    yaw = radians(yaw)

    # Calculate the magnitude of the acceleration vector
    acc_magnitude = sqrt(ax ** 2 + ay ** 2 + az ** 2)

    # Normalize the acceleration vector
    if acc_magnitude != 0:
        ax /= acc_magnitude
        ay /= acc_magnitude
        az /= acc_magnitude

    # Convert pitch, roll, and yaw angles to a Vector3
    x = cos(yaw) * cos(roll)
    y = sin(yaw) * cos(roll)
    z = sin(roll)

    return [x,y,z]


import math

import math


def calculate_vector_coordinates(accel_x, accel_y, accel_z, gyro_x, gyro_y, gyro_z, dt):
    # Normalize accelerometer readings
    accel_mag = math.sqrt(accel_x ** 2 + accel_y ** 2 + accel_z ** 2)
    accel_x_norm = accel_x / accel_mag
    accel_y_norm = accel_y / accel_mag
    accel_z_norm = accel_z / accel_mag

    # Calculate the direction of the vector based on accelerometer data
    vector_dir_x = -accel_x_norm  # Negate for opposite direction
    vector_dir_y = -accel_y_norm
    vector_dir_z = -accel_z_norm

    # Integrate the angular velocity to obtain the estimated orientation
    gyro_x_rad = math.radians(gyro_x)  # Convert from degrees to radians
    gyro_y_rad = math.radians(gyro_y)
    gyro_z_rad = math.radians(gyro_z)
    roll, pitch, yaw = integrate_gyro_data(accel_x, accel_y, accel_z,gyro_x_rad, gyro_y_rad, gyro_z_rad, dt)

    # Combine the accelerometer and orientation data to obtain the final direction of the vector
    cos_roll = math.cos(roll)
    sin_roll = math.sin(roll)
    cos_pitch = math.cos(pitch)
    sin_pitch = math.sin(pitch)
    cos_yaw = math.cos(yaw)
    sin_yaw = math.sin(yaw)

    x = -cos_pitch * sin_yaw * vector_dir_x + (cos_roll * cos_yaw + sin_roll * sin_pitch * sin_yaw) * vector_dir_y + (
                sin_roll * cos_yaw - cos_roll * sin_pitch * sin_yaw) * vector_dir_z
    y = cos_pitch * cos_yaw * vector_dir_x + (cos_roll * sin_yaw - sin_roll * sin_pitch * cos_yaw) * vector_dir_y + (
                sin_roll * sin_yaw + cos_roll * sin_pitch * cos_yaw) * vector_dir_z
    z = sin_pitch * vector_dir_x - sin_roll * cos_pitch * vector_dir_y + cos_roll * cos_pitch * vector_dir_z

    # Calculate the intersection point with the unit sphere
    intersection_mag = 1.0  # Radius of the unit sphere
    intersection_x = x * intersection_mag
    intersection_y = y * intersection_mag
    intersection_z = z * intersection_mag

    return intersection_x, intersection_y, intersection_z


def integrate_gyro_data(accel_x, accel_y, accel_z,gyro_x, gyro_y, gyro_z, dt):
    # Integrate the angular velocity to obtain the estimated orientation
    roll = 0.0
    pitch = 0.0
    yaw = 0.0

    roll += gyro_x * dt
    pitch += gyro_y * dt
    yaw += gyro_z * dt
    # Apply complementary filter to combine the estimated orientation with accelerometer data
    alp=0.98
    # Complementary filter coefficient

    accel_roll = math.atan2(accel_y, accel_z)
    accel_pitch = math.atan2(-accel_x, math.sqrt(accel_y ** 2 + accel_z ** 2))

    roll = alp * roll + (1 - alp) * accel_roll
    pitch = alp * pitch + (1 - alp) * accel_pitch

    return roll, pitch, yaw


# def calculate_vector_coordinates(accel_x, accel_y, accel_z):
#     # Normalize accelerometer readings
#     accel_mag = math.sqrt(accel_x ** 2 + accel_y ** 2 + accel_z ** 2)
#     accel_x_norm = accel_x / accel_mag
#     accel_y_norm = accel_y / accel_mag
#     accel_z_norm = accel_z / accel_mag
#
#     # Calculate the direction of the vector
#     vector_dir_x = -accel_x_norm  # Negate for opposite direction
#     vector_dir_y = -accel_y_norm
#     vector_dir_z = -accel_z_norm
#
#     # Calculate the intersection point with the unit sphere
#     intersection_mag = 1.0  # Radius of the unit sphere
#     intersection_x = vector_dir_x * intersection_mag
#     intersection_y = vector_dir_y * intersection_mag
#     intersection_z = vector_dir_z * intersection_mag
#
#     return intersection_x, intersection_y, intersection_z


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
        # sword_rot[0] = cos(time)
        # sword_rot[2] = sin(time)
        a = serialcomm.readline().decode('utf8', 'ignore')
        lenOfOutputStr=50
        if (len(a) == lenOfOutputStr):
            b = decodeInfo(a)
            # print(b, a+'G')
            sensor_data = b  # example sensor data
            orientation = calculate_vector_coordinates(sensor_data[0],sensor_data[1],sensor_data[2],sensor_data[3],sensor_data[4],sensor_data[5],0.05)
            # print(orientation)
            sword_rot[0]=orientation[0]
            sword_rot[2]=orientation[1]
            sword_rot[1]=orientation[2]
        # else:
            # print(len(a), a)
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
