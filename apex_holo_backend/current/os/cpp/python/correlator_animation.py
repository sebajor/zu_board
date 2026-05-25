import argparse
import numpy as np
import socket
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
import time
from collections import deque

parser = argparse.ArgumentParser(
    description="Plot snapshots from zuboard.")
parser.add_argument("-i", "--ip", dest="ip", default="10.0.6.88",
    help="zuboard IP address.")

parser.add_argument("-p", "--p", dest='port', default=12234,
                    help="port number")

msg = 'HOLO:ZUBOARD:GET_REG'
samples_read = 10
samples_display = 128



if __name__ == '__main__':
    args = parser.parse_args()
    data = []
    fig, axes = plt.subplots(1,2)
    line, = axes[0].plot([],[])
    data.append(line)
    line, = axes[1].plot([],[])
    data.append(line)
    axes[0].set_xlim(0, samples_display)
    axes[1].set_xlim(0, samples_display)
    axes[0].set_ylim(-80,80)
    axes[1].set_ylim(-180,180)
    axes[0].grid()
    axes[1].grid()

    phase_data = deque(maxlen=samples_display)
    power_data = deque(maxlen=samples_display)
    




    ##connect to the socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((args.ip, args.port))

    ##in case  that the correlator is not initialized
    sock.send('HOLO:ZUBOARD:ENABLE_CORR'.encode())
    print(sock.recv(4096))


    def recv_all_data(sock):
        sock.send(msg.encode())
        length = 52
        raw_data = b''
        while(len(raw_data)<length):
            more = sock.recv(length-len(raw_data))
            if not more:
                raise ConnectionError("Connection broken!")
            raw_data += more
        return raw_data

    def get_correlation(sock):
        raw_data = recv_all_data(sock)
        dat = np.frombuffer(raw_data[20:], 'i8') 
        return dat

    def animate(_):
        aux = np.zeros((samples_read, 4))
        for i  in range(samples_read):
            aux = get_correlation(sock)
            power = 10*(np.log10(aux[0])-np.log10(aux[1]))
            phase = np.rad2deg(np.arctan2(aux[3], aux[2])) 
            power_data.append(power)
            phase_data.append(phase)

        data[0].set_data(range(len(power_data)),power_data)
        data[1].set_data(range(len(phase_data)),phase_data)
        return data

    ani = FuncAnimation(fig, animate, interval=100)
    plt.show()


        
