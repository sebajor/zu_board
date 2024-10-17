#!/home/seba/.pyenv/versions/2.7.18/bin/python
import socket
import corr, os, time
import calandigital as calan
import re
import numpy as np

roach_ip = '192.168.1.12'
boffile= 'vv_casper.bof'
SERVER_ADDR = './uds_socket'    #unit domain socket
RECV_LEN = 16384
DEBUG = False


class roach_intf():
    
    def __init__(self, roach_ip, boffile,  server_addr, debug=True, filename='roach_data.npz',
                 integ_time=0.5):
        try:
            os.unlink(server_addr)
        except Exception as e:
            print("Error {:}".format(e))
        #create socket
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.sock.bind(server_addr)
        if(debug):
            self.roach = calan.DummyRoach(roach_ip)
        else:
            #self.roach = calan.initialize_roach(ip=roach_ip, boffile=boffile)
            self.roach = corr.katcp_wrapper.FpgaClient(roach_ip)
            time.sleep(1)
            self.roach.upload_program_bof(boffile, 3000)
        time.sleep(1)
        valon_freq = 135*1e6
        self.fpga_clk = valon_freq/8
        self.channels = 2**13
        self.set_integration_time(integ_time)
        self.filename = filename
        self.pow0_store = []
        self.pow1_store = []
        self.corr_store = []

        
        

    def set_integration_time(self, integ_time=0.5):
        channel_period = self.channels/self.fpga_clk
        self.n_acc = int(integ_time/channel_period)
        self.roach.write_int('acc_len', self.n_acc)
        self.roach.write_int('cnt_rst', 1)
        self.roach.write_int('cnt_rst', 0)
        
    def get_power_data(self):
        spect0 = self.roach.read('1_A2', 8192*8)
        spect1 = self.roach.read('1_B2', 8192*8)
        return spect0, spect1

    def get_corr_data(self):
        corr_re = self.roach.read('AB_re', 8192*8)
        corr_im = self.roach.read('AB_im', 8192*8)
        return corr_re, corr_im

    def main_loop(self, recv_len=1024):
        print("Starting main loop")
        self.sock.listen(1)
        while(1):
            connection, client = self.sock.accept()
            try:
                print("client connected")
                while(1):
                    msg = connection.recv(recv_len)
                    print(msg)
                    msg = msg.decode()
                    if(msg=='ROACH:GET_POW'):
                        self.send_power_data(connection)
                    elif(msg=='ROACH:GET_CORR'):
                        self.send_corr_data(connection)
                    elif(msg=='ROACH:FLUSH'):
                        self.save_data()
                    else:
                        pass
            except Exception as e:
                print(e)

    def send_power_data(self, connection):
        """
        """
        spect0, spect1, = self.get_power_data()
        msg = spect0+spect1
        print(len(msg))
        pow0_data = np.frombuffer(spect0, '>Q')
        pow1_data = np.frombuffer(spect1, '>Q')
        self.pow0_store.append(pow0_data)
        self.pow1_store.append(pow1_data)
        connection.sendall(msg)


    def send_corr_data(self, connection):
        corr_re, corr_im = self.get_corr_data()
        msg = corr_re+corr_im
        corr_re_data = np.frombuffer(corr_re, '>q')
        corr_im_data = np.frombuffer(corr_im, '>q')
        self.corr_store.append(corr_re_data+1j*corr_im_data)
        connection.sendall(msg)

    def save_data(self):
        np.savez(self.filename, 
                 pow0 = np.array(self.pow0_store),
                 pow1 = np.array(self.pow1_store),
                 corr = np.array(self.corr_store)
                 )
        self.pow0_store = []
        self.pow1_store = []
        self.corr_store = []
        


if __name__ == '__main__':
    vv_server = roach_intf(roach_ip=roach_ip, 
                           boffile=boffile,
                           server_addr=SERVER_ADDR,
                           debug=DEBUG
                           )
    vv_server.main_loop()




