from machine import Timer, SPI, Pin
from max31855 import MAX31855 # thermocouple
import ujson
import usocket 

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
preheat_1 = {"len": 60000, "temp": 100}
preheat_2 = {"len": 60000, "temp": 150}
soak = {"len": 90000, "temp": 183}
reflow = {"len": 60000, "temp": 225}
cool = {"len": 30000, "temp": 20}

def encode_temp(sensor):
    return ujson.dumps({"temp": sensor.read()})


def send_data(sock, data):
    sock.send(data + "\n")

address = ("192.168.11.26", 9000)

s = usocket.socket(usocket.AF_INET, usocket.SOCK_STREAM)
s.connect(address)

# create oven, turn it off...
oven = Pin(2, Pin.OUT)
oven.off()

spi = SPI(1, baudrate=5000000, polarity=0, phase=0)
cs = Pin(16, Pin.OUT)

tc = MAX31855(spi, cs) #termocouple

tim = Timer(-1)

tim.init(period=2500, mode=Timer.PERIODIC, callback=lambda t:send_data(s, encode_temp(tc)))