import numpy as np
import matplotlib.pyplot as plt
from client import *
from calandigital.instruments.visa_generator import visa_generator
from calandigital.instruments.vna_e8364c import vna_E8364C
from roach_vv_client import roach_client

filename = 'debug'

zuboard_ip = "192.168.7.2"

gen1_name = 'TCPIP::192.168.1.34::INST'       ##reference
gen2_name = 'TCPIP::192.168.1.33::INST'    ##signal

vna_type =  'roach'#None                             #can be None, vna or roach
vna_name = 'TCPIP::192.168.1.123::INST'
vna_points = 8192

server_addr = './uds_socket'
roach_ind = 1214        ##index ot save

power_range = [-3, -103]#[8, -102]
power_points = 21

ref_sweep = False
ref_power = [-3,-3]#[8, 8]
ref_points = 4

##make a phase sweep.. note that the only the rohde schwartz can do the phase sweep
phase_sweep = False     
phase_range = [0,360]
phase_points = 21

##zu board parameters
sleeping = 60
fs = 100
freq = 10

acc_len = 32
dft_size = 1024
k = 102
vna_rbw = 100*1e3    ##resolution bandwidth 100kHz
twidd_binpt = 14

adc_points = 1024
bram_points = 512 


def phase_sweep_meas(zuboard, gen_sig, phases, sleep, vna=None,
                     zu_points=1024, vna_points=1):
    """
    vna: its vna or the roach
    """
    zu_pow0= np.zeros((len(phases), zu_points))
    zu_pow1= np.zeros((len(phases), zu_points))
    zu_corr = np.zeros((len(phases), zu_points), dtype=complex)
    if(vna is not None):
        vna_pow = np.zeros((len(phases), vna_points))
        vna_corr = np.zeros((len(phases), vna_points), dtype=complex)

    for i, phase in enumerate(phases):
        print("Phase: %f"%phase)
        gen_sig.set_phase_deg(phase)
        time.sleep(sleep)
        pow0, pow1 = zuboard.get_power_data()
        corr_re, corr_im = zuboard.get_corr_data()
        zu_pow0[i,:] = pow0
        zu_pow1[i,:] = pow1
        zu_corr[i,:] = corr_re+1j*corr_im
        if(vna is not None):
            pow_vna, corr_re, corr_im = vna.correlator_get()
            vna_pow[i,:] = pow_vna
            vna_corr[i,:] = corr_re+1j*corr_im
    if(vna is not None):
        return [zu_pow0, zu_pow1, zu_corr, vna_pow, vna_corr]
    return [zu_pow0, zu_pow1, zu_corr]



def signal_sweep_meas(zuboard, gen_sig, sig_powers, sleep, phases=None,
                    vna=None, zu_points=1024, vna_points=1):
    if(phases is not None):
        zu_pow0 = np.zeros((len(sig_powers), len(phases), zu_points))
        zu_pow1 = np.zeros((len(sig_powers), len(phases), zu_points))
        zu_corr = np.zeros((len(sig_powers), len(phases), zu_points), dtype=complex)
        if(vna is not None):
            vna_pow = np.zeros((len(sig_powers), len(phases), vna_points))
            vna_corr = np.zeros((len(sig_powers), len(phases), vna_points), dytpe=complex)
    else:
        zu_pow0 = np.zeros((len(sig_powers), zu_points))
        zu_pow1 = np.zeros((len(sig_powers), zu_points))
        zu_corr = np.zeros((len(sig_powers), zu_points), dtype=complex)
        if(vna is not None):
            vna_pow = np.zeros((len(sig_powers), vna_points))
            vna_corr = np.zeros((len(sig_powers), vna_points), dtype=complex)
    
    for i, sig in enumerate(sig_powers):
        gen_sig.set_power_dbm(sig)
        print("Set power signal: %f"%sig)
        if(phases is not None):
            phase_out = phase_sweep_meas(zuboard, gen_sig, phases=phase, sleep=sleep, vna=vna,
                                         zu_points=zu_points, vna_points=vna_points)
            zu_pow0[i,:,:] = phases_out[0]
            zu_pow1[i,:,:] = phases_out[1]
            zu_corr[i,:,:] = phases_out[2]
            if(vna is not None):
                vna_pow[i,:,:] = phases_out[3]
                vna_corr[i,:,:] = phases_out[4]
        else:
            time.sleep(sleep)
            pow0, pow1 = zuboard.get_power_data()
            corr_re, corr_im = zuboard.get_corr_data()
            zu_pow0[i,:] = pow0
            zu_pow1[i,:] = pow1
            zu_corr[i,:] = corr_re+1j*corr_im
            if(vna is not None):
                pow_vna, corr_re, corr_im = vna.correlator_get()
                vna_pow[i,:] = pow_vna
                vna_corr[i,:] = corr_re+1j*corr_im
    if(vna is not None):
        return [zu_pow0, zu_pow1, zu_corr, vna_pow, vna_corr]
    return [zu_pow0, zu_pow1, zu_corr]


def quick_psweep_plot(zu_pow0, zu_pow1, zu_corr, powers_sig, vna_pow=None, 
                      vna_corr=None, axes=None, vna_type='roach', meas_type='power'):
    if(meas_type=='phase'):
        x_label = 'Input phase difference [deg]'
    else:
        x_label = 'Input power difference [dB]'
    if(axes is None):
        fig, axes = plt.subplots(2,2)
    pow0_db = 10*np.log10(zu_pow0)
    pow1_db = 10*np.log10(zu_pow1)
    pow_diff = pow0_db-pow1_db
    phase = np.rad2deg(np.angle(zu_corr))

    phase_avg = np.mean(phase, axis=1)
    phase_std = np.std(phase, axis=1)
    pow_diff_avg = np.mean(pow_diff, axis=1)
    pow_diff_std = np.std(pow_diff, axis=1)

    axes[0,0].plot(powers_sig[0]-powers_sig, pow_diff_avg, '*-', color='darkblue', label='LTC ADCs')
    axes[0,1].plot(powers_sig[0]-powers_sig, pow_diff_std, '*-', color='darkblue')
    axes[1,0].plot(powers_sig[0]-powers_sig, phase_avg, '*-', color='darkblue')
    axes[1,1].plot(powers_sig[0]-powers_sig, phase_std, '*-', color='darkblue')

    axes[0,0].set_ylabel('Measured power avg [dB]')
    axes[1,0].set_ylabel('Measured phase avg [deg]')
    axes[0,1].set_ylabel('Measured power std [dB]')
    axes[1,1].set_ylabel('Measured phase std [deg]')

    
    for ax in axes.flatten():
        ax.grid()
        ax.set_xlabel(x_label)
    if(vna_pow is not  None):
        vna_pow_db = 10*np.log10(vna_pow)
        axes[0,0].plot(powers_sig[0]-powers_sig, np.mean(vna_pow_db, axis=1), '*-', color='darkred', label=vna_type)
        handles, labels = axes[0,0].get_legend_handles_labels()
        fig.legend(handles, labels, loc='upper right')

    if(vna_corr is not None):
        vna_phase = np.rad2deg(np.angle(vna_corr))
        axes[1,0].plot(powers_sig[0]-powers_sig, np.mean(vna_phase, axis=1) , '*-', color='darkred', label=vna_type)
    return axes




if __name__ == '__main__':
    zuboard = correlator_1bin_client(ip=zuboard_ip)
    gen_ref = visa_generator(gen1_name)
    gen_sig = visa_generator(gen2_name)

    if(vna_type == 'vna'):
        vna_type = vna_E8364C(vna_name)
        vna.correlator_setup(freq*1e6, rbw=vna_rbw, avg=32)
    elif(vna_type == 'roach'):
        vna = roach_client(server_addr)
        vna.correlator_setup(roach_ind)
    else:
        vna = None
    powers_ref = ref_power
    phases = None
    if(ref_sweep):
        powers_ref = np.linspace(ref_power[0], ref_power[1], ref_points)
    if(phase_sweep):
        phases = np.linspace(phase_range[0], phase_range[1], phase_points)

    powers_signal = np.linspace(power_range[0], power_range[1], power_points)
    ##setup generators
    gen_ref.set_freq_mhz(freq)
    gen_ref.set_power_dbm(powers_ref[0])
    gen_sig.set_freq_mhz(freq)
    gen_sig.set_power_dbm(powers_signal[0])
    gen_sig.turn_output_on()
    gen_ref.turn_output_on()

    if(ref_sweep):
        print("Start ref sweep")
    else:
        out = signal_sweep_meas(zuboard, gen_sig, powers_signal, sleeping, phases=phases,
                    vna=vna, zu_points=bram_points, vna_points=vna_points)

    gen_ref.turn_output_off()
    gen_sig.turn_output_off()

    if(vna is not None):
        np.savez(filename, 
                 powers_signal = powers_signal,
                 powers_ref = powers_ref,
                 phases = phases,
                 zu_pow0=out[0],
                 zu_pow1=out[1],
                 zu_corr=out[2],
                 vna_pow = out[3],
                 vna_corr = out[4]
                 )
    else:
        np.savez(filename, 
                 powers_signal = powers_signal,
                 powers_ref = powers_ref,
                 phases = phases,
                 zu_pow0=out[0],
                 zu_pow1=out[1],
                 zu_corr=out[2]
                 )

