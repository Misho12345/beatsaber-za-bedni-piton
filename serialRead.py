import serial
serialcomm = serial.Serial('COM5', 38400,timeout=0.005)
lenOfOutputStr=66
# serialcomm.timeout = 1
from math import *
def decodeInfo(string):
    result = ['','','','','','','','']
    if len(string)==lenOfOutputStr:
        o=0
        i=3
        while i<len(string):
            for j in range(5):
                result[o]+=string[i+j]
            o+=1
            i+=8
        for i in range(len(result)):
            result[i]=float(result[i])
    return result
# for i in range(100):
#     print(serialcomm.readline().decode('utf8', 'ignore'))
