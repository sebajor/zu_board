from matplotlib.animation import FuncAnimation
from client import *


def main():

    zuboard_ip = '192.168.7.2'
    fs = 100    ##mhz
    bits = 14
    points = 1024
    corr_points = 512
    time_axis = np.arange(points)
    freqs = np.linspace(0, fs/2, points//2)
    dBFS = 6.02*bits + 1.76 + 10*np.log10(points)
    corr_axis = np.arange(corr_points)

    fpga_intf = correlator_1bin_client(ip=zuboard_ip)
    time.sleep(0.1)
    
    fig, axes = plt.subplots(4,2)
    data = []
    axes = axes.flatten()
    for i in range(4):
        ax = axes[i]
        ax.set_xlim(0, corr_points)
        ax.grid()
        line, = ax.plot([],[], animated=True)
        data.append(line)
    axes[0].set_ylim(0,170)
    axes[1].set_ylim(0,170)
    axes[2].set_ylim(-180,180)
    axes[3].set_ylim(-5,80)
    axes[0].set_title('ADC0 power')
    axes[0].set_ylabel('dB')
    axes[1].set_title('ADC1 power')
    axes[1].set_ylabel('dB')
    axes[2].set_title('Correlator phase')
    axes[2].set_ylabel("deg")
    axes[3].set_title('Power difference')
    axes[3].set_ylabel("dB")
    for i in range(4,8):
        ax = axes[i]
        if(i%2):
            ax.set_xlim(0, fs/2)
            ax.set_ylim(-dBFS-2, 0)
            ax.grid()
        else:
            ax.set_xlim(0,points)
            ax.set_ylim(-2**13, 2**13)
            ax.set_xlabel("ADC%i"%(i//4))
            ax.grid()
        line, = ax.plot([],[], animated=True)
        data.append(line)
    fig.set_tight_layout(True)
    axes[4].set_title("ADC0 time")
    axes[5].set_title("ADC0 spectra")
    axes[6].set_title("ADC1 time")
    axes[7].set_title("ADC1 spectra")
        
    def animate(_):
        power0, power1 = fpga_intf.get_power_data()
        power0_db = 10*np.log10(np.abs(power0))
        power1_db = 10*np.log10(np.abs(power1))
        corr_re, corr_im = fpga_intf.get_corr_data()
        phase = np.rad2deg(np.arctan2(corr_im, corr_re))
        adc0, adc1, spec0, spec1 = fpga_intf.get_power_spectra()
        data[0].set_data(corr_axis, power0_db)
        data[1].set_data(corr_axis, power1_db)
        data[2].set_data(corr_axis, phase)
        data[3].set_data(corr_axis, power0_db-power1_db)
        data[4].set_data(time_axis, adc0)
        data[5].set_data(freqs, 20*np.log10(np.abs(spec0[:points//2]+1))-dBFS)
        data[6].set_data(time_axis, adc1)
        data[7].set_data(freqs, 20*np.log10(np.abs(spec1[:points//2]+1))-dBFS)
        return data
    
    ani = FuncAnimation(fig, animate, blit=True)
    plt.show()

if __name__ == '__main__':
    main()



