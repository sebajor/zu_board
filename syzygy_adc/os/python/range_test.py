from client import *
from calandigital.instruments.visa_generator import visa_generator

gen_name = 'TCPIP::10.0.6.248::INST'
zuboard_ip = "192.168.7.2"

ref_power = 'ref_0'

sleeping = 1
fs = 100
freq = 10

acc_len = 32
dft_size = 1024
k = 102
twidd_binpt = 14

power_range = [8, -102]
power_points = 12
adc_points = 1024

if __name__ == '__main__':
    zuboard = snapshot_client(ip=zuboard_ip)
    gen = visa_generator(gen_name)
    powers = np.linspace(power_range[0], power_range[1], power_points)
    gen.set_freq_mhz(freq)
    gen.set_power_dbm(power_range[0])
    adc0 = np.zeros((power_points, adc_points))
    adc1 = np.zeros((power_points, adc_points))
    gen.turn_output_on()
    for i, power in enumerate(powers):
        #gen.set_power_dbm(power)
        input("put %f dbm press when ready"%power) 
        time.sleep(sleeping)
        dat0, dat1 = zuboard.get_snapshot_data()
        adc0[i,:] = dat0
        adc1[i,:] = dat1
    gen.turn_output_off()
    gen.instr.close()
    np.savez('vv_data_'+ref_power,
             powers = powers,
             adc0 = adc0,
             adc1 = adc1)

    spect0 = np.fft.fft(adc0, axis=1)
    spect1 = np.fft.fft(adc1, axis=1)
    
    fig, axes = plt.subplots(2)
    pow_diff = 20*(np.log10(np.abs(spect0[:,k]))-np.log10(np.abs(spect1[:,k])))
    phase_diff = np.rad2deg(np.angle(spect0[:,k]*np.conj(spect1[:,k])))
    axes[0].plot(powers-powers[0], pow_diff, '*-')
    axes[1].plot(powers-powers[0], phase_diff, '*-')
    axes[0].grid()
    axes[1].grid()
    plt.show()
    



