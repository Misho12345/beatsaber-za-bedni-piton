import time
import threading

print(threading.active_count())


def printsmt():
    time.sleep(3)
    print('A')


x = threading.Thread(target=printsmt, args=())
x.start()
y = threading.Thread(target=printsmt, args=())
y.start()
printsmt()
printsmt()
