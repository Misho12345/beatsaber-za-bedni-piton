from main import *
import math
import threading
from typing import List
from serialRead import *

swordWorking = True

a = 'Ax:+1.04Ay:-0.03Az:-0.23Gx:+0.00Gy:+0.00Gz:+0.00'


class Vector3:
    def __init__(self, x, y, z):
        self.x = x
        self.y = y
        self.z = z


def normalize_vector(vector):
    magnitude = math.sqrt(vector.x ** 2 + vector.y ** 2 + vector.z ** 2)
    return Vector3(vector.x / magnitude, vector.y / magnitude, vector.z / magnitude)


def intersect_camera_with_sphere(camera_direction):
    sphere_center = Vector3(0.0, 0.0, 0.0)
    sphere_radius = 1
    camera_direction = normalize_vector(camera_direction)
    sphere_to_camera = Vector3(
        camera_direction.x - sphere_center.x,
        camera_direction.y - sphere_center.y,
        camera_direction.z - sphere_center.z
    )

    a = camera_direction.x * camera_direction.x + \
        camera_direction.y * camera_direction.y + \
        camera_direction.z * camera_direction.z

    b = 2 * (sphere_to_camera.x * camera_direction.x +
             sphere_to_camera.y * camera_direction.y +
             sphere_to_camera.z * camera_direction.z)

    c = sphere_to_camera.x * sphere_to_camera.x + \
        sphere_to_camera.y * sphere_to_camera.y + \
        sphere_to_camera.z * sphere_to_camera.z - sphere_radius * sphere_radius

    discriminant = b * b - 4 * a * c
    if discriminant < 0:
        # No intersection
        return None

    t = (-b - math.sqrt(discriminant)) / (2 * a)
    intersection_point = Vector3(
        camera_direction.x * t + sphere_center.x,
        camera_direction.y * t + sphere_center.y,
        camera_direction.z * t + sphere_center.z
    )

    return intersection_point


def get_orientation(sensor_data: List[float]):
    # Extract accelerometer and gyroscope data from sensor_data
    ax, ay, az, gx, gy, gz = sensor_data

    # Calculate pitch and roll angles using accelerometer data
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

    return [x, y, z]


def calculate_vector_coordinates(accel_x, accel_y, accel_z, gyro_x, gyro_y, gyro_z, dt):
    # Normalize accelerometer readings
    accel_mag = sqrt(accel_x ** 2 + accel_y ** 2 + accel_z ** 2)
    accel_x_norm = accel_x / accel_mag
    accel_y_norm = accel_y / accel_mag
    accel_z_norm = accel_z / accel_mag

    # Calculate the direction of the vector based on accelerometer data
    vector_dir_x = -accel_x_norm  # Negate for opposite direction
    vector_dir_y = -accel_y_norm
    vector_dir_z = -accel_z_norm

    # Integrate the angular velocity to obtain the estimated orientation
    gyro_x_rad = radians(gyro_x)  # Convert from degrees to radians
    gyro_y_rad = radians(gyro_y)
    gyro_z_rad = radians(gyro_z)
    roll, pitch, yaw = integrate_gyro_data(accel_x, accel_y, accel_z, gyro_x_rad, gyro_y_rad, gyro_z_rad, dt)

    # Combine the accelerometer and orientation data to obtain the final direction of the vector
    cos_roll = cos(roll)
    sin_roll = sin(roll)
    cos_pitch = cos(pitch)
    sin_pitch = sin(pitch)
    cos_yaw = cos(yaw)
    sin_yaw = sin(yaw)

    x = -cos_pitch * sin_yaw * vector_dir_x + (cos_roll * cos_yaw + sin_roll * sin_pitch * sin_yaw) * vector_dir_y + (
            sin_roll * cos_yaw - cos_roll * sin_pitch * sin_yaw) * vector_dir_z
    y = cos_pitch * cos_yaw * vector_dir_x + (cos_roll * sin_yaw - sin_roll * sin_pitch * cos_yaw) * vector_dir_y + (
            sin_roll * sin_yaw + cos_roll * sin_pitch * cos_yaw) * vector_dir_z
    z = sin_pitch * vector_dir_x - sin_roll * cos_pitch * vector_dir_y + cos_roll * cos_pitch * vector_dir_z

    intersection_mag = 1.0  # Radius of the unit sphere
    intersection_x = x * intersection_mag
    intersection_y = y * intersection_mag
    intersection_z = z * intersection_mag

    return intersection_x, intersection_z, intersection_y


def integrate_gyro_data(accel_x, accel_y, accel_z, gyro_x, gyro_y, gyro_z, dt):
    roll = 0.0
    pitch = 0.0
    yaw = 0.0

    roll += gyro_x * dt
    pitch += gyro_y * dt
    yaw += gyro_z * dt
    alp = 0.98

    accel_roll = atan2(accel_y, accel_z)
    accel_pitch = atan2(-accel_x, sqrt(accel_y ** 2 + accel_z ** 2))

    roll = alp * roll + (1 - alp) * accel_roll
    pitch = alp * pitch + (1 - alp) * accel_pitch

    return roll, pitch, yaw


def rotate_sword(sword_rot):
    print(sword_dir)
    serial_output = serial_com.readline().decode('utf8', 'ignore')
    if len(serial_output) == lenOfOutputStr:
        b = decode_info(serial_output)
        sensor_data = b  # example sensor data
        orientation = calculate_vector_coordinates(sensor_data[9], sensor_data[10], sensor_data[11], sensor_data[12],
                                                   sensor_data[13], sensor_data[14], 0.05)

        sword_rot[0] = orientation[0]
        sword_rot[2] = orientation[1]
        sword_rot[1] = orientation[2]


def start_rotating():
    x = threading.Thread(target=rotate_sword, args=sword_dir)
    x.start()
