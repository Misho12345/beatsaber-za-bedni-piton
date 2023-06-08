import serial

serial_com = serial.Serial('COM11', 9600, timeout=1)
lenOfOutputStr = 63

serialOutput = serial_com.readline().decode('utf8', 'ignore')


def decode_info(string):
    result = []
    final = list(string.split(','))
    for i in range(16):
        result.append(float(final[i]))
    return result
