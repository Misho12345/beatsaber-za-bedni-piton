import win32con
import win32api
from pynput.keyboard import Controller
from serialRead import *

keyboard = Controller()
sensitivity = -66


# port = serial.Serial()
# port.baudrate = 9600
# port.port = "COM5"
# port.open()


def move(d, s):
    if d == 'up':
        win32api.mouse_event(win32con.MOUSEEVENTF_MOVE, int(s), 0)
    elif d == 'down':
        win32api.mouse_event(win32con.MOUSEEVENTF_MOVE, int(s), 0)
    elif d == 'left':
        win32api.mouse_event(win32con.MOUSEEVENTF_MOVE, 0, int(s))
    elif d == 'right':
        win32api.mouse_event(win32con.MOUSEEVENTF_MOVE, 0, int(s))


# def lclick():
#     win32api.mouse_event(win32con.MOUSEEVENTF_LEFTDOWN,0,0)
# def lup():
#     win32api.mouse_event(win32con.MOUSEEVENTF_LEFTUP,0,0)
# def rclick():
#     win32api.mouse_event(win32con.MOUSEEVENTF_RIGHTDOWN,0,0)
# def rup():
#     win32api.mouse_event(win32con.MOUSEEVENTF_RIGHTUP,0,0)

FB = 0
EB = 0
space = '0'
AB = '0'
BB = '0'
CB = '0'
DB = '0'


def run_joystick():
    # while True:
    # if port.in_waiting:
    #     a = port.readline().decode('utf8', 'ignore')
    #     Final = a.split(',')
    #     final = list(Final)
    # global space
    # global AB
    # global BB
    # global CB
    # global DB
    #
    # if final[2]=='0':
    #     keyboard.release(" ")
    #     # print(keyboard.pressed(" "))
    # elif final[2] == '1' and space=='0':
    #     keyboard.press(" ")
    #     pass
    #
    # ux = final[0]
    # uy = final[1]
    # space = final[2]
    # AB = final[3]
    # BB = final[4]
    # CB = final[5]
    # DB = final[6]
    #
    # global FB
    # global EB
    #
    # if FB == '1' and final[7] == '0':
    #     pyautogui.click()
    # if EB == '1' and final[8] == '0':
    #     pyautogui.click(button='right')
    #
    # FB = final[7]
    # EB = final[8]
    #
    # if AB == '1':
    #     keyboard.press("w")
    # else:
    #     keyboard.release("w")
    # if BB == '1':
    #     keyboard.press("d")
    # else:
    #     keyboard.release("d")
    # if CB == '1':
    #     keyboard.press("s")
    # else:
    #     keyboard.release("s")
    # if DB == '1':
    #     keyboard.press("a")
    # else:
    #     keyboard.release("a")
    # print(1)
    serial_output = serial_com.readline().decode('utf8', 'ignore')
    if len(serial_output) == lenOfOutputStr:
        result = decode_info(serial_output)
        ux = result[0]
        uy = result[1]
        x = int(ux)
        y = int(uy)

        offset_x = 521
        offset_y = 512
        if y > 330:
            move('left', (-(y - offset_y) / 100) * sensitivity)
        elif y < 330:
            move('right', (-(y - offset_y) / 100) * sensitivity)
        if x > 330:
            move('up', ((x - offset_x) / 100) * sensitivity)
        elif x < 330:
            move('down', ((x - offset_x) / 100) * sensitivity)
        else:
            move('.', None)
        output = []
        for i in range(6):
            output.append(result[i + 2])
        return output
    else:
        return -1

# x = threading.Thread(target=runJoystick(), args=())
# x.start()
