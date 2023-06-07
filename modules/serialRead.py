import serial

serialcomm = serial.Serial('COM5', 9600, timeout=1)
lenOfOutputStr = 63
# serialcomm.timeout = 1

serialOutput = serialcomm.readline().decode('utf8', 'ignore')
# a = port.readline().decode('utf8', 'ignore')
# Final = a.split(',')
# final = list(Final)
# 521,512,0,0,0,0,0,0,0,-0.29,-0.79,-0.69,+0.02,-0.01,+0.02
def decodeInfo(string):
    result = []
    # a = port.readline().decode('utf8', 'ignore')

    Final = string.split(',')
    final = list(Final)
    # if len(string) == lenOfOutputStr:
    #     o = 0
    #     i = 3
    #     while i < len(string) - 2:
    #         for j in range(5):
    #             result[o] += string[i + j]
    #         o += 1
    #         i += 8
    #     for i in range(len(result)):
    #         result[i] = float(result[i])
    for i in range(16):
        result.append(float(final[i]))
    return result
# for i in range(100):
#     print(serialcomm.readline().decode('utf8', 'ignore'))
