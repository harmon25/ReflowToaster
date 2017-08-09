#from machine import Timer
import utime as time
from reflow_oven import ReflowOven
# SPI = 
# DO -> D6 (12)
# CLK -> D5 (14)
# CS -> D0 (16)
# 60 = 114
# 120 = 
#D4 = 2
#D0 = 16
#D3 = 0
#oven.on()
#oven.off()

controller_address = ("192.168.25.104", 9000)

reflowOven = ReflowOven(thermocouple, oven, controller_address, wlan)

retries = 10
retry = 0
while retry <= retries:
    reflowOven = reflowOven.connect()
    if reflowOven.check_connected():
        break
    else:
        print("Failed attempt {0}".format(retry))
        time.sleep(15)
    retry += 1

if reflowOven.check_connected():
    print("Connected!")
    reflowOven.say_hello()
    while True:
        reflowOven.loop()
else:
    print("Failed to connect after {0} retries, reboot to try again".format(retries))
        