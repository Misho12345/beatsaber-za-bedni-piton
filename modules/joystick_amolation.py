import win32con, win32api
import serial.tools.list_ports
# in command prompt, type "pip install pynput" to install pynput.
from pynput.keyboard import Key, Controller
import pyautogui
import time
import threading
from serialRead import *
keyboard = Controller()
sensytyvyty = -66
# port = serial.Serial()
# port.baudrate = 9600
# port.port = "COM5"
# port.open()


def move(D, s):
    if D == 'up':
        win32api.mouse_event(win32con.MOUSEEVENTF_MOVE, int(s), 0)
    elif D == 'down':
        win32api.mouse_event(win32con.MOUSEEVENTF_MOVE, int(s), 0)
    elif D == 'left':
        win32api.mouse_event(win32con.MOUSEEVENTF_MOVE, 0, int(s))
    elif D == 'right':
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
space ='0'
AB ='0'
BB ='0'
CB ='0'
DB ='0'

def runJoystick():
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
    serialOutput = serialcomm.readline().decode('utf8', 'ignore')
    if(len(serialOutput)==lenOfOutputStr):
        result = decodeInfo(serialOutput)
        ux = result[0]
        uy = result[1]
        x = int(ux)
        y = int(uy)

        offset=512
        if y > 330:
            move('left', (-(y - offset) / 100) * sensytyvyty)
        elif y < 330:
            move('right', (-(y - offset) / 100) * sensytyvyty)
        if x > 330:
            move('up', ((x - offset) / 100) * sensytyvyty)
        elif x < 330:
            move('down', ((x - offset) / 100) * sensytyvyty)
        else:
            move('.')
        output=[]
        for i in range(6):
            output.append(result[i+2])
        return output
    else:
        return -1




# x = threading.Thread(target=runJoystick(), args=())
# x.start()

