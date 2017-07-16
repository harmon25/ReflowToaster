# This file is executed on every boot (including wake-boot from deepsleep)
#import esp
#esp.osdebug(None)
import gc
import webrepl
from machine import Pin, SPI
from max31855 import MAX31855 # thermocouple

webrepl.start()
gc.collect()

SSID = "*****"
PSK = "******"

OVEN_RELAY_PIN = 2
TC_CS_PIN = 16

def do_connect():
    import network
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    if not wlan.isconnected():
        print('connecting to network...')
        wlan.connect(SSID, PSK)
        while not wlan.isconnected():
            pass
    print('network config:', wlan.ifconfig())
    return wlan

# create oven, turn it off...
oven = Pin(OVEN_RELAY_PIN, Pin.OUT)
oven.off()

#initialize SPI for thermocouple
spi = SPI(1, baudrate=5000000, polarity=0, phase=0)
cs = Pin(TC_CS_PIN, Pin.OUT)

#initalize thermocouple
thermocouple = MAX31855(spi, cs) 
# connect to wifi
wlan = do_connect()                     