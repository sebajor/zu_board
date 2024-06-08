import numpy as np
import socket, time
import matplotlib.pyplot as plt
import ipdb


class snapshot_client():

    def __init__(self, ip='192.168.7.2', port=1234, _timeout=5, _sleep=0.2):
        self.client = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.client.settimeout(_timeout)
        self.sleep = _sleep
        self.client.connect((ip, port))

    def get_snapshot_data(self):
        msg = "ZUBOARD:GET_SNAPSHOT"
        self.client.send(msg.encode())
        time.sleep(self.sleep)
        ans = self.client.recv(2**15)
        data = np.frombuffer(ans, 'h')
        adc0 = data[:len(data)//2]
        adc1 = data[len(data)//2:]
        return adc0, adc1

    def get_power_spectra(self, fs=100, plot=False):
        adc0, adc1 = self.get_snapshot_data()
        spec0 = np.fft.fft(adc0)
        spec1 = np.fft.fft(adc1)
        if(plot):
            freq = np.linspace(0, fs, len(spec0))
            fig, axes = plt.subplots(2,2)
            axes[0,0].plot(adc0)
            axes[0,1].plot(freq, 20*np.log10(np.abs(spec0)), label='adc0')
            axes[1,0].plot(adc1)
            axes[1,1].plot(freq, 20*np.log10(np.abs(spec1)), label='adc1')
            for i in range(2):
                for j in range(2):
                    axes[i,j].set_title('ADC %i'%i)
                    axes[i,j].grid()
            axes[0,0].set_ylim(-2**13, 2**13)
            axes[1,0].set_ylim(-2**13, 2**13)
            fig.set_tight_layout(True)
            plt.show()
        return adc0, adc1,spec0, spec1
