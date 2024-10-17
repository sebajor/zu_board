from client import *
from calandigital.instruments.visa_generator import visa_generator

zuboard_ip = "192.168.7.2"
gen1_name = "TCPIP::192.168.1.34::INSTR"
gen2_name = "TCPIP::192.168.1.33::INSTR"

sleeping = 0.1#20#0.1
fs = 100    #mhz

acc_len = 32
dft_size = 1024
k = 102
twidd_binpt = 14

ref_power = [0, -30]
ref_points = 4
test_freq = 10          #mhz
power_range = [-0, -110]  #dbm
power_points = 11#31
adc_points = 1024
phase_points = 21#181

plot = True

bram_size = 512

if __name__ == '__main__':
    zuboard = correlator_1bin_client(ip=zuboard_ip)
    gen1 = visa_generator(gen1_name)
    gen2 = visa_generator(gen2_name)
    powers = np.linspace(power_range[0], power_range[1], power_points)
    ref_powers = np.linspace(ref_power[0], ref_power[1], ref_points)
    phases = np.linspace(-180,180, phase_points)
    gen1.set_freq_mhz(test_freq)
    gen2.set_freq_mhz(test_freq)
    gen1.set_power_dbm(power_range[0])
    gen2.set_power_dbm(power_range[0])
    
    power0 = np.zeros((ref_points, power_points, phase_points, bram_size))
    power1 = np.zeros((ref_points, power_points, phase_points, bram_size))
    corr = np.zeros((ref_points, power_points, phase_points, bram_size), dtype=complex)
    adc0 = np.zeros((ref_points, power_points, phase_points, adc_points))
    adc1 = np.zeros((ref_points, power_points, phase_points, adc_points))
    for j, ref in enumerate(ref_powers):
        gen1.set_power_dbm(ref)
        for i,power in enumerate(powers):
            for k, phase in enumerate(phases):
                print("ref:%f, test: %f"%(ref, power))
                gen1.set_phase_deg(phase)
                gen2.set_power_dbm(power)
                time.sleep(sleeping)
                pow0, pow1 = zuboard.get_power_data()
                corr_re, corr_im = zuboard.get_corr_data()
                power0[j,i,k,:] = pow0
                power1[j,i,k,:] = pow1
                corr[j,i,k,:] = corr_re+1j*corr_im
                adc0_data, adc1_data = zuboard.get_snapshot_data()
                adc0[j,i,k,:] = adc0_data
                adc1[j,i,k,:] = adc1_data
    #end the meas
    np.savez("vv_data",
             ref_powers = ref_powers,
             powers = powers, 
             phase= phase,
             corr = corr,
             power0 = power0,
             power1 = power1,
             adc0=adc0,
             adc1=adc1
             )
            


    """
    fig, axes = plt.subplots(2,2)
    for ax in axes.flatten():
        ax.grid()
        ax.set_xlim(power_range[0], power_range[0]-power_range[-1])

    """
