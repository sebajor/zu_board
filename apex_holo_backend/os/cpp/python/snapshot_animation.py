import argparse
import numpy as np
import socket
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
import time

parser = argparse.ArgumentParser(
    description="Plot snapshots from zuboard.")
parser.add_argument("-i", "--ip", dest="ip", default="10.0.6.113",
    help="zuboard IP address.")

parser.add_argument("-p", "--p", dest='port', default=12234,
                    help="port number")

parser.add_argument("-fft", '--fft', dest='fft', action='store_true',
                    help="plot the spectrum also")
parser.add_argument("-samples", "--samples", dest="samples", default=2**14, type=int, 
                    help="Number of samples to use")


bits = 14
msg = 'HOLO:ZUBOARD:GET_SNAPSHOT\n'


if __name__ == '__main__':
    args = parser.parse_args()
    data = []
    #create the figure
    time_x = np.arange(args.samples)
    if(args.fft):
        freq = np.linspace(0,50, args.samples//2)
        fig, axes = plt.subplots(2,2)
        for i in range(2):
            axes[0,i].set_xlim(0, args.samples)
            axes[0,i].set_ylim(-2**13, 2**13)
            axes[0,i].grid()
            axes[1,i].set_xlim(0, 50)
            axes[1,i].set_ylim(0,160)
            axes[1,i].grid()
            line, = axes[0,i].plot([],[],animated=True)
            data.append(line)
            line, = axes[1,i].plot([],[],animated=True)
            data.append(line)

    else:
        fig, axes = plt.subplots(1,2)
        for ax in axes.flatten():
            ax.set_xlim(0, args.samples)
            ax.set_ylim(-2**13, 2**13)
            ax.grid()
            line, = ax.plot([],[],animated=True)
            data.append(line)

    ##connect to the socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((args.ip, args.port))

    def recv_all_data(sock):
        sock.send(msg.encode())
        length = 65574
        data = b''
        while(len(data)<length):
            more = sock.recv(length-len(data))
            if not more:
                raise ConnectionError("Connection broken!")
            data += more
        return data
    
    def animate(_):
        raw_data = recv_all_data(sock)
        adc0 = np.frombuffer(raw_data[31:2**14*2+31], 'i2')
        adc1 = np.frombuffer(raw_data[32+2**14*2+5:-1], 'i2')
        if(len(data)==4):
            spect0 = np.fft.fft(adc0[:args.samples])
            spect1 = np.fft.fft(adc1[:args.samples])
            data[0].set_data(time_x[:args.samples], adc0[:args.samples])
            data[1].set_data(freq, 20*np.log10(np.abs(spect0[:args.samples//2])))
            data[2].set_data(time_x[:args.samples], adc1[:args.samples])
            data[3].set_data(freq, 20*np.log10(np.abs(spect1[:args.samples//2])))
        else:
            data[0].set_data(time_x[:args.samples], adc0[:args.samples])
            data[1].set_data(time_x[:args.samples], adc1[:args.samples])
        return data

    ani = FuncAnimation(fig, animate, blit=True, interval=200)
    plt.show()

