import sys
sys.path.append('../')
import numpy as np
from calandigital.instruments.visa_generator import visa_generator
from zu_client import *
import time, datetime

##
##  In apex I just have one genereator :( so I connect both inputs using a splitter
##


filename = 'data'
zu_ip = '10.0.6.238'

gen_name = 'ASRL/dev/ttyUSB1::INSTR'

power_range = [-3,-103]
power_points = 51#21
power_sleep = 30

phase_points = 16
phase_sleep = 10

integ_time = 0.5    #sec
fs = 100            #mhz
fft_points = 1024   
freq = 21.4



powers = np.linspace(power_range[0], power_range[1], power_points)
phases = np.linspace(-180, 180, phase_points)

gen = visa_generator(gen_name)

gen.set_freq_mhz(freq)
gen.set_power_dbm(power_range[0])
gen.set_phase_deg(phases[0])

gen.turn_output_on()

client = apex_holo_client(zu_ip, cmd_port, data_port)
client.set_dft_size(fft_points)
time.sleep(0.5)
client.set_integration_time(integ_time)
time.sleep(0.5)
client.set_frequency_to_acquire(freq*1e6)

raw_power_data= []
raw_phase_data = []
power_stamps = np.zeros(powers.shape)
phase_stamps = np.zeros((power_points, phase_points))

client.enable_correlator()

for i, power in enumerate(powers):
    start = time.time()
    power_stamps[i] = start
    gen.set_power_dbm(power)
    gen.set_phase_deg(phases[0])
    ##first we take some data only for the power
    print(power)
    while((time.time()-start)<power_sleep):
        try:
            msg = client.data_sock.recv(1024)
            raw_power_data.append(msg)
        except:
            pass
    for j, phase in enumerate(phases):
        start =  time.time()
        phase_stamps[i,j] = time.time()
        gen.set_phase_deg(phase)
        while((time.time()-start)<phase_sleep):
            try:
                msg = client.data_sock.recv(1024)
                raw_phase_data.append(msg)
            except:
                pass

gen.turn_output_off()

power_data = np.array([np.frombuffer(x, 'd') for x in raw_power_data])
power_data = power_data.reshape((-1,5))

phase_data = np.array([np.frombuffer(x, 'd') for x in raw_phase_data])
phase_data = phase_data.reshape((-1,5))

np.savez('phase_sweep_data', 
         power_data = power_data,
         phase_data = phase_data,
         powers = powers,
         power_stamps = power_stamps,
         phases = phases,
         phase_stamps=phase_stamps)

