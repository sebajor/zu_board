import numpy as np
import argparse
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
import time
from zu_client import *



parser = argparse.ArgumentParser(
    description="Plot snapshots from zuboard.")
parser.add_argument("-i", "--ip", dest="ip", default="10.0.6.88",
    help="zuboard IP address.")

parser.add_argument("-p", "--p", dest='port', default=12234,
                    help="port number")


fs = 100    #mhz
fft_size = 1024



args = parser.parse_args()
data = []

fig, axes = plt.subplots(2,2)
freq = np.linspace(0,fs, fft_size)


for ax in axes.flatten():
    line, = ax.plot([],[])
    data.append(line)
    ax.set_xlim(0, fs)
    ax.set_ylim(0, 200)     ##counts...
    ax.grid()
    
axes[1,1].set_ylim(-180,180)

axes[0,0].set_ylabel('ADC0 spectra dB')
axes[0,1].set_ylabel('ADC1 spectra dB')
axes[1,0].set_ylabel('Correlation spectra dB')
axes[1,1].set_ylabel('Correlation phase')


##connect to the fpga
zu = zu_client(ip=args.ip, port=args.port)



def animate(_):
    pow0, pow1 = zu.get_powers()
    corr = zu.get_correlation()
    data[0].set_data(freq, 10*np.log10(pow0))
    data[1].set_data(freq, 10*np.log10(pow1))
    data[2].set_data(freq, 10*np.log10(corr))
    data[3].set_data(freq, np.angle(corr))
    return data





ani = FuncAnimation(fig, animate, interval=100)
plt.show()










