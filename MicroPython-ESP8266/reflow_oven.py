import ujson
import time
import usocket

class ReflowOven:
    def __init__(self, tc, oven, controller_addr, wlan, debug=False):
        self.tc = tc
        self.oven = oven
        self.reflowing = False
        self.current_stage = -1 # -1 == off
        self.tcp_sock = None
        self._read_interval = 1000
        self._last_read = 0
        self._reflow_start_time = 0
        self._cycle_start_time = 0
        self.ip = wlan.ifconfig()[0]
        self.pause_interval = False
        self.current_temp = 0
        self.controller_addr = controller_addr
        self.connected = False
        self._debug = debug

        self._CYCLES = [{"len": 90000, "temp": 160, "name": "PREHEAT"},
                        {"len": 75000, "temp": 185, "name": "SOAK"},
                        {"len": 50000, "temp": 225, "name": "REFLOW"}]

    def check_connected(self):
        return self.connected

    def connect(self):
        self.tcp_sock = usocket.socket(usocket.AF_INET, usocket.SOCK_STREAM)
        self.tcp_sock.settimeout(500)

        try:
            self.tcp_sock.connect(self.controller_addr)
            self.connected = True
            self.tcp_sock.setblocking(False)
        except:
            self.connected = False

        return self

    def hello_msg(self):
        return {"msg_type": "HELLO", "data": self.ip, "err": False}

    def error_msg(self, error):
        return {"msg_type": error, "err": True}

    def ok_msg(self):
        return {"msg_type": "OK", "err": False}
    
    def stage_msg(self):
        return {"msg_type": "STAGE", "data": self.current_stage, "err": False}

    def temp_msg(self):
        return {"msg_type": "TEMP", "data": self.current_temp, "err": False}

    def send_data(self, data_dict):
        json_str = ujson.dumps(data_dict)
        sent = self.tcp_sock.send(json_str + "\n")
        return sent

    def say_hello(self):
        msg = self.hello_msg()
        return self.send_data(msg)

    def start_reflow(self):
        if self.reflowing:
            err_msg = self.error_msg("Cannot start - Already reflowing")
            return self.send_data(err_msg)
        else:
            now = time.ticks_ms()
            self._reflow_start_time = now
            self.reflowing = True
            self.next_stage()
            msg = self.ok_msg()
            return self.send_data(msg)

    def stop_reflow(self):
        if self.reflowing:
            self.reflowing = False
            self.current_stage = -1
            msg = self.ok_msg()
            return self.send_data(msg)
        else:
            err_msg = self.error_msg("Cannot stop - Not Reflowing")
            return self.send_data(err_msg)
        
    def reflow_stage(self):
        msg = self.stage_msg()
        self.send_data(msg)

    def next_stage(self):
        self.current_stage += 1
        self._cycle_start_time = time.ticks_ms()
        print("Starting stage: {0}".format(self._CYCLES[self.current_stage]["name"]))
        print("Current temp: {0}".format(self.tc.read()))

    def read_temp(self):
        new_temp = self.tc.read()
        self.current_temp = new_temp
        msg = self.temp_msg()
        return self.send_data(msg)

    def handle_command(self):
        json_cmd = None
        try:
            json_cmd = self.tcp_sock.readline(500)
        except:
            self.connected = False
        
        if json_cmd:
            # block socket so as not to send
            # temp data as resposnse           
            cmd_dict = ujson.loads(json_cmd)

            if self._debug:
                print("Recieved cmd_type: {0}".format(cmd_dict["cmd_type"]))

            if cmd_dict["cmd_type"] == "READ_TEMP":
                return self.read_temp()

            if cmd_dict["cmd_type"] == "START_REFLOW":
                return self.start_reflow()

            if cmd_dict["cmd_type"] == "STOP_REFLOW":
                return self.stop_reflow()

            if cmd_dict["cmd_type"] == "REFLOW_STAGE":
                return self.reflow_stage()
            # unblock for sending temp data.

    def handle_reflow(self):
        if self.reflowing:
            now = time.ticks_ms()
            current_reflow_time = now - self._reflow_start_time
            current_stage_time = now - self._cycle_start_time
            this_cycle = self._CYCLES[self.current_stage]
            #if self.current_stage == (len(self._CYCLES) - 1):

            if self.tc.read() >= this_cycle["temp"] :
                # oven is as hot as it needs to be, turn off
                self.oven.off()
            elif self.tc.read() < this_cycle["temp"] and self.oven.value() == 0:
                # oven is not hot enough, and is off, turn on
                self.oven.on()
            
            # if we need to move to next stage of reflow, iter stage 
            if current_stage_time >= this_cycle["len"] and (len(self._CYCLES) - 1) == self.current_stage:
                self.oven.off()
                print("Reflow Complete")
                print("Current temp: {0}".format(self.tc.read()))
                print("Total time: {0}".format(current_reflow_time))

                self.reflowing = False
                self.current_stage = -1
            elif current_stage_time >= this_cycle["len"]:
                self.next_stage()


    def loop(self):
        self.handle_reflow()
        if self.connected:
            self.handle_command()
       



