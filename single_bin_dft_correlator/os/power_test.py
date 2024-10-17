from client import *
#from calandigital.instruments.visa_generator import visa_generator

#gen_name = 'TCPIP::10.0.6.248::INST'
zuboard_ip = "192.168.7.2"

ref_power = 'ref_0'

sleeping = 5
fs = 100
freq = 10

acc_len = 32
dft_size = 1024
k = 102
twidd_binpt = 14

power_range = [8, -102]
power_points = 12
adc_points = 1024
corr_data_points = 512


if __name__ == '__main__':
    zuboard = correlator_1bin_client(ip=zuboard_ip)
    #gen = visa_generator(gen_name)
    powers = np.linspace(power_range[0], power_range[1], power_points)
    #gen.set_freq_mhz(freq)
    #gen.set_power_dbm(power_range[0])
    adc0 = np.zeros((power_points, adc_points))
    adc1 = np.zeros((power_points, adc_points))
    power0 = np.zeros((power_points, corr_data_points))
    power1 = np.zeros((power_points, corr_data_points))
    corr = np.zeros((power_points, corr_data_points), dtype=complex)
    #gen.turn_output_on()
    for i, power in enumerate(powers):
        #gen.set_power_dbm(power)
        input("put %f dbm press when ready"%power) 
        time.sleep(sleeping)
        dat0, dat1 = zuboard.get_snapshot_data()
        adc0[i,:] = dat0
        adc1[i,:] = dat1
        pow0, pow1 = zuboard.get_power_data()
        corr_re, corr_im = zuboard.get_corr_data()
        power0[i,:] = pow0
        power1[i,:] = pow1
        corr[i,:] = corr_re+1j*corr_im
    #gen.turn_output_off()
    #gen.instr.close()
    np.savez('vv_data_'+ref_power,
             powers = powers,
             adc0 = adc0,
             adc1 = adc1,
             power0 = power0,
             power1 = power1,
             corr = corr)

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
    

    pow0_db = 10*np.log10(power0)
    pow1_db = 10*np.log10(power1)
    ang = np.rad2deg(np.angle(corr))

    fig, axes = plt.subplots(2,2)
    axes[0,0].plot(powers-powers[0], np.mean(pow0_db, axis=1)-np.mean(pow1_db, axis=1), '*-')
    axes[0,1].plot(powers-powers[0], np.std(pow0_db, axis=1)+np.std(pow1_db, axis=1), '*-')
    axes[1,0].plot(powers-powers[0], np.mean(ang, axis=1), '*-')
    axes[1,1].plot(powers-powers[0], np.std(ang, axis=1), '*-')

    for ax in axes.flatten():
        ax.grid()








