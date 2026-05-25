import socket
import numpy as np
import time

#ip ='10.17.90.157'
ip ='10.0.6.229'
cmd_port =12234
data_port = 12235

class apex_holo_client():
    def __init__(self, ip, cmd_port, data_port, _sleep=0.1, _timeout=2):
        self.cmd_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.cmd_sock.connect((ip,cmd_port))
        self._sleep = _sleep
        self.cmd_sock.settimeout(_timeout)

        self.data_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.data_sock.connect((ip,data_port))
        self.data_sock.settimeout(_timeout)
        self.clock = 100*1e6
        self.acc_len = 16384*3      #0.5s
        self.k = 102
        self.dft_size = 1024
        self.twiddle_point = 14
        self.snapshot_samples = 1024

    

    def enable_correlator(self):
        msg = "HOLO:ZUBOARD:ENABLE_CORR"
        self.cmd_sock.send(msg.encode())

    def disable_correlation(self):
        msg = "HOLO:ZUBOARD:DISABLE_CORR"
        self.cmd_sock.send(msg.encode())

    def set_accumulation(self, acc):
        msg = "HOLO:ZUBOARD:SET_ACC {:}".format(acc)
        self.cmd_sock.send(msg.encode())
        self.acc_len = acc

    def set_integration_time(self, integ_time):
        acc = self.clock*integ_time/self.dft_size
        print(acc)
        acc = np.round(acc)
        self.set_accumulation(acc)

    def set_twiddle_factor(self,k):
        msg = "HOLO:ZUBOARD:SET_TWIDDLE {:}".format(k)
        self.cmd_sock.send(msg.encode())
        self.k = k

    def set_frequency_to_acquire(self, freq):
        df = self.clock/(self.dft_size)
        k = freq/df
        print(k)
        k = np.round(k)
        self.set_twiddle_factor(k)

    def set_dft_size(self, dft_size):
        msg = "HOLO:ZUBOARD:SET_DFT_SIZE {:}".format(dft_size)
        self.cmd_sock.send(msg.encode())
        self.dft_size = dft_size

    def get_snapshot(self):
        msg = "HOLO:ZUBOARD:GET_SNAPSHOT"
        self.cmd_sock.send(msg.encode())
        raw_data = self.cmd_sock.recv(2**14*4) 
        ##I have to check that I got both adc...but also this is too hard
        while(len(raw_data)< 2*self.snapshot_samples*2):
            raw_data +=  self.cmd_sock.recv(2**14*4)
        data = np.frombuffer(raw_data, 'i2')
        return data

