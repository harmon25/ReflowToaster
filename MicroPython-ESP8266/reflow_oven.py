import ujson
import time
import usocket

class ReflowOven:
    def __init__(self, tc, oven, controller_addr, wlan):
        self.tc = tc
        self.oven = oven
        self.reflowing = False
        self.current_stage = -1 # -1 == off
        self.tcp_sock = None
        self._read_interval = 1500
        self._last_read = 0
        self.ip = wlan.ifconfig()[0]
        self.pause_interval = False
        self.current_temp = 0
        self.controller_addr = controller_addr
        self.connected = False


        self._CYCLES = [{"len": 60000, "temp": 100, "name": "PREHEAT_1"}, 
                        {"len": 60000, "temp": 150, "name": "PREHEAT_2"},
                        {"len": 90000, "temp": 183, "name": "SOAK"},
                        {"len": 60000, "temp": 225, "name": "REFLOW"},
                        {"len": 30000, "temp": 20, "name": "COOL"}]

    def check_connected(self):
        return self.connected

    def connect(self):
        self.tcp_sock = usocket.socket(usocket.AF_INET, usocket.SOCK_STREAM)
        self.tcp_sock.settimeout(500)

        try:
            self.tcp_sock.connect(self.controller_addr)
            self.connected = True
        except:
            self.connected = False

        return self

    def hello_msg(self):
        return {"MSG": "HELLO", "DATA": self.ip, "ERROR": False}

    def error_msg(self, error):
        return {"MSG": error, "ERROR": True}

    def ok_msg(self):
        return {"MSG": "OK", "ERROR": False}
    
    def stage_msg(self):
        return {"MSG": "STAGE", "DATA": self.current_stage, "ERROR": False}

    def temp_msg(self):
        return {"MSG": "TEMP", "DATA": self.current_temp, "ERROR": False}

    def send_data(self, data_dict):
        json_str = ujson.dumps(data_dict)
        sent = self.tcp_sock.send(json_str + "\n")
        return sent

    def say_hello(self):
        msg = self.hello_msg()
        return self.send_data(msg)

    def start_reflow(self):
        print("start reflowing")
        if self.reflowing:
            err_msg = self.error_msg("Cannot start - Already reflowing")
            return self.send_data(err_msg)
        else:
            msg = self.ok_msg()
            self.reflowing = True
            self.current_stage = 0
            return self.send_data(msg)

    def stop_reflow(self):
        print("stop reflowing")
        if self.reflowing:
            self.reflowing = False
            self.current_stage = -1
            msg = self.ok_msg()
            return self.send_data(msg)
        else:
            err_msg = self.error_msg("Cannot stop - Not Reflowing")
            return self.send_data(err_msg)
        
    def reflow_stage(self):
        print("reflow stage")
        msg = self.stage_msg()
        self.send_data(msg)

    def read_temp(self):
        print("read temp")
        new_temp = self.tc.read()
        self.current_temp = new_temp
        msg = self.temp_msg()
        print(msg)
        return self.send_data(msg)

    def handle_command(self):
        json_cmd = self.tcp_sock.readline(500)
        
        if json_cmd:
            # block socket so as not to send
            # temp data as resposnse
            
            cmd_dict = ujson.loads(json_cmd)

            if cmd_dict["cmd"] == "READ_TEMP":
                sent = self.read_temp()
                print(sent)
                return sent

            if cmd_dict["cmd"] == "START_REFLOW":
                return self.start_reflow()

            if cmd_dict["cmd"] == "STOP_REFLOW":
                return self.stop_reflow()

            if cmd_dict["cmd"] == "REFLOW_STAGE":
                return self.reflow_stage()
            # unblock for sending temp data.


    def loop(self):
        now = time.ticks_ms()
        self.handle_command()



