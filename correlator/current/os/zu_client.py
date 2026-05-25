import numpy as np
import matplotlib.pyplot as plt
import socket
import time


class zu_client():


    def __init__(self, ip, port, _sleep=0.1):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.connect((ip, port))
        self._sleep= _sleep

    def set_acc_len(self, acc_len):
        msg = 'ZUBOARD:SET_ACC '+str(acc_len)
        self.sock.send(msg.encode())
        time.sleep(self._sleep)
        ans = self.sock.recv(1024).decode()
        print(ans)

    def get_powers(self):
        msg = 'ZUBOARD:GET_POW'
        self.sock.send(msg.encode())
        time.sleep(self._sleep)
        ans = self.sock.recv(16384)
        pow0 = np.frombuffer(ans[:8192], 'q')
        pow1 = np.frombuffer(ans[8192:], 'q')
        return pow0, pow1

    def get_correlation(self):
        msg = 'ZUBOARD:GET_CORR'
        self.sock.send(msg.encode())
        time.sleep(self._sleep)
        ans = self.sock.recv(16384)
        r12_re = np.frombuffer(ans[:8192], 'q')
        r12_im = np.frombuffer(ans[8192:], 'q')
        return r12_re+1j*r12_im

        

