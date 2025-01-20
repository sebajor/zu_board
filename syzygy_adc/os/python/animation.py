from matplotlib.animation import FuncAnimation
from client import *


def main():

    zuboard_ip = '192.168.7.2'
    fs = 100    ##mhz
    bits = 14
    points = 1024
    time_axis = np.arange(points)
    freqs = np.linspace(0, fs, points)
    dBFS = 6.02*bits + 1.76 + 10*np.log10(points)

    fpga_intf = snapshot_client(ip=zuboard_ip)
    time.sleep(0.1)

    fig, axes = plt.subplots(2,2, squeeze=False)
    data = []
    for i in range(2):
        axes[i,0].set_xlim(0, points)
        axes[i,0].set_ylim(-2**13, 2**13)
        axes[i,0].set_title("ADC0 snapshot")
        axes[i,1].set_xlim(0, fs)
        axes[i,1].set_ylim(-dBFS-2, 0)
        axes[i,1].set_title("ADC0 spectra")
        axes[i,0].grid()
        axes[i,1].grid()
        line0, = axes[i,0].plot([],[], animated=True)
        line1, = axes[i,1].plot([],[], animated=True)
        data.append(line0)
        data.append(line1)

    def animate(_):
        adc0, adc1, spec0, spec1 = fpga_intf.get_power_spectra()
        data[0].set_data(time_axis, adc0)
        data[1].set_data(freqs, 20*np.log10(np.abs(spec0+1))-dBFS)
        data[2].set_data(time_axis, adc1)
        data[3].set_data(freqs, 20*np.log10(np.abs(spec1+1))-dBFS)
        return data
    
    ani = FuncAnimation(fig, animate, blit=True)
    plt.show()

if __name__ == '__main__':
    main()



