import numpy as np
import socket
import time
import ipdb


SERVER_ADDR = './uds_socket'    #unit domain socket

class roach_client ():
    def __init__(self, server_addr):
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        try:
            self.sock.connect(server_addr)
        except socket.error as msg:
            logging.error(msg)
            sys.exit()
    
    def correlator_setup(self, freq_ind):
        self.freq_ind = freq_ind
        
    
    def get_pow_data(self):
        self.sock.sendall("ROACH:GET_POW".encode())
        time.sleep(0.8)
        #ipdb.set_trace()
        raw_data = self.sock.recv(8192*8*4)
        print(len(raw_data)/(8192*8))
        pow0 = np.frombuffer(raw_data[:8192*8], '>Q')
        pow1 = np.frombuffer(raw_data[8192*8:8192*8*2], '>Q')
        return [pow0,pow1]

    def get_corr_data(self):
        self.sock.sendall("ROACH:GET_CORR".encode())
        time.sleep(0.8)
        #ipdb.set_trace()
        raw_data = self.sock.recv(8192*8*2)
        print(len(raw_data)/(8192*8))
        corr_re= np.frombuffer(raw_data[:8192*8], '>q') ##something weird happens here!!
        corr_im = np.frombuffer(raw_data[8192*8:8192*8*2], '>q')
        return corr_re+1j*corr_im


    def correlator_get(self):
        pow0, pow1 = self.get_pow_data()
        corr_data = self.get_corr_data()
        pow_diff = pow0[self.freq_ind]/pow1[self.freq_ind]
        return pow_diff, corr_data.real[self.freq_ind], corr_data.imag[self.freq_ind]
    
    def send_stop(self):
        self.sock.sendall('ROACH:FLUSH'.encode())
        
        
