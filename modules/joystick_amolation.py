import win32con, win32api
import serial.tools.list_ports
# in command prompt, type "pip install pynput" to install pynput.
from pynput.keyboard import Key, Controller
import pyautogui
keyboard = Controller()
sensytyvyty=3
port = serial.Serial()
port.baudrate = 9600
port.port = "COM5"
port.open()


def move(D,s):
    if (D=='up'):
        win32api.mouse_event(win32con.MOUSEEVENTF_MOVE, int(s), 0)
    elif (D=='down'):
        win32api.mouse_event(win32con.MOUSEEVENTF_MOVE, int(s), 0)
    elif(D=='left'):
        win32api.mouse_event(win32con.MOUSEEVENTF_MOVE, 0, int(s))
    elif(D=='right'):
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



def main():
    while True:
        if port.in_waiting:
            a = port.readline().decode('utf8', 'ignore')
            # print(len(a))
            Final = a.split(',')
            final = list(Final)
            ux = final[0]
            uy = final[1]
            space = final[2]
            AB = final[3]
            BB = final[4]
            CB = final[5]
            DB = final[6]


            global FB
            global EB


            if FB == '1' and final[7]=='0':
                pyautogui.click()
            if EB == '1' and final[8]=='0':
                pyautogui.click(button='right')

            FB = final[7]
            EB = final[8]



            # print(final)
            if(space=='1'):
                keyboard.press(" ")
            else:
                keyboard.release(" ")
            if (AB == '1'):
                keyboard.press("w")
            else:
                keyboard.release("w")
            if (BB == '1'):
                keyboard.press("d")
            else:
                keyboard.release("d")
            if (CB == '1'):
                keyboard.press("s")
            else:
                keyboard.release("s")
            if (DB == '1'):
                keyboard.press("a")
            else:
                keyboard.release("a")
            x = int(ux)
            y = int(uy)

            if(y>330):
                move('left',(-(y-330)/100)*sensytyvyty)
            elif(y<330):
                move('right',(-(y-330)/100)*sensytyvyty)
            if (x>330):
                move('up',((x-335)/100)*sensytyvyty)
            elif(x<330):
                move('down',((x-335)/100)*sensytyvyty)
            else:
                move('.')


main()
