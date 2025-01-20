import socket 
import numpy as np
import time

ip = '10.0.6.123'
port = 12234

iters = 100
samples = 2**16

class snapshot_client():
    def __init__(self, ip, port, _sleep=0.1, _timeout=2):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.connect((ip,port))
        self._sleep = _sleep
        self.sock.settimeout(_timeout)

    def get_snapshot(self, samples=2**16+5):
        msg = "HOLO:ZUBOARD:GET_SNAPSHOT"
        self.sock.send(msg.encode())
        time.sleep(self._sleep)
        msg_size = 0
        raw_data = b""
        while(msg_size < samples*2*2):
            dat = self.sock.recv(samples*2)
            raw_data += dat
            msg_size += len(dat)
        #raw_data = self.sock.recv(samples*2)
        print(len(raw_data))
        ##usually we dont get the complete data at once.. we need to iterate to
        ##get all the data
        data = np.frombuffer(raw_data, 'u2')
        adc0 = data[:samples]
        adc1 = data[samples:]
        return adc0, adc1

if __name__ == '__main__':
    client = snapshot_client(ip, port)
    adc0_data = np.zeros((iters, sampes))
    adc1_data = np.zeros((iters, sampes))
    for i in range(iters):
        adc0, adc1 = get_snapshot(samples=samples+5)
        adc0_data[i,:] = adc0[:samples]
        adc1_data[i,:] = adc1[:samples]


