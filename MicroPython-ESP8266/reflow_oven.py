import ujson
import time

class ReflowOven:
    def __init__(self, tc, oven, server_address, my_address, sock):
        self.tc = tc
        self.oven = oven
        self.reflowing = False
        self.current_stage = -1 # -1 == off
        self.tcp_sock = sock 
        self._read_interval = 1000
        self._last_read = 0
        self.ip = my_address
        self.pause_interval = False
        self.current_temp = 0

        self.tcp_sock.connect(server_address)

        self._CYCLES = [{"len": 60000, "temp": 100, "name": "PREHEAT_1"}, 
                        {"len": 60000, "temp": 150, "name": "PREHEAT_2"},
                        {"len": 90000, "temp": 183, "name": "SOAK"},
                        {"len": 60000, "temp": 225, "name": "REFLOW"},
                        {"len": 30000, "temp": 20, "name": "COOL"}]


    def send_data(self, data_dict):
        json_str = ujson.dumps(data_dict)
        return self.tcp_sock.send(json_str + "\n")

    def say_hello(self):
        self.tcp_sock.setblocking(True)
        self.send_data({"MSG": "HELLO", "DATA": self.ip, "ERROR": False})
        self.tcp_sock.setblocking(False)

    def start_reflow(self):
        print("start reflowing")
        if self.reflowing:
            self.send_data({"MSG": "Cannot start - Already reflowing", "ERROR": True})
        else:
            self.reflowing = True
            self.current_stage = 0
            self.send_data( {"MSG": "OK", "ERROR": False})

    def stop_reflow(self):
        print("stop reflowing")
        if self.reflowing:
            self.reflowing = False
            self.current_stage = -1
            self.send_data({"MSG": "OK", "ERROR": False})
        else:
            self.send_data({"MSG": "Cannot stop - Not Reflowing", "ERROR": True})
        
    def reflow_stage(self):
        print("reflow stage")
        self.send_data({"MSG": self.current_stage, "ERROR": False})

    def read_temp(self):
        new_temp = self.tc.read()
        self.current_temp = new_temp
        return {"temp": self.current_temp}

    def handle_command(self):
        json_cmd = self.tcp_sock.readline(200)
        
        if json_cmd:
            # block socket so as not to send
            # temp data as resposnse
            self.tcp_sock.setblocking(True)
            cmd_dict = ujson.loads(json_cmd)
            if cmd_dict["cmd"] == "START_REFLOW":
                self.start_reflow()

            if cmd_dict["cmd"] == "STOP_REFLOW":
                self.stop_reflow()

            if cmd_dict["cmd"] == "REFLOW_STAGE":
                self.reflow_stage()
            # unblock for sending temp data.
            self.tcp_sock.setblocking(False)


    def loop(self):
        now = time.ticks_ms()
        self.handle_command()
        if time.ticks_diff(now, self._last_read) >= self._read_interval:
            self._last_read = time.ticks_ms()
            t = self.read_temp()
            self.send_data(t)



