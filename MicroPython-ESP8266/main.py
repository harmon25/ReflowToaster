#from machine import Timer
import time
import usocket 
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
        

address = ("192.168.11.27", 9000)
#tim = Timer(-1)
s = usocket.socket(usocket.AF_INET, usocket.SOCK_STREAM)

int_config = wlan.ifconfig()

reflowOven = ReflowOven(thermocouple, oven, address, int_config[0], s )

#start = time.ticks_ms() # get millisecond counter

try:
    reflowOven.say_hello()
#    tim.init(period=2000, mode=Timer.PERIODIC, callback=lambda t:send_data(s, encode_temp(thermocouple)))

except:
    print("failed to initialize connection to reflow controller\nCheck IP address and that controller is running")

while True:
    reflowOven.loop()
    #now = time.ticks_ms()
    #cmd = s.readline(100)
    #handle_command(cmd, s)

    #if time.ticks_diff(now, last_read) >= 1500:
    #    last_read = time.ticks_ms()
    #    send_data(s, encode_temp(thermocouple))
        