from serialRead import *
import mouse

# move 100 right & 100 down
mouse.move(100, 100, absolute=False, duration=0.2)
def moveMouse():
    a = serialcomm.readline().decode('utf8', 'ignore')
    if(len(a)==lenOfOutputStr):
        b=decodeInfo(a)
        print(b[6])
        mouse.move(10*(b[6]-3.33),-10*(b[7]-3.33), absolute=False, duration=0.2)
    else:
        print("a:",len(a))
    # print(a)
#     Ax:+1.04Ay:-0.03Az:-0.23Gx:+0.00Gy:+0.00Gz:+0.00Jx:3.38Jy:33.30
for i in range(1000):
    moveMouse()
seruil.close()