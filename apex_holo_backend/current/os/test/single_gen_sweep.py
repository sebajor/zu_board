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
zu_ip = '10.0.6.221'

gen_name = 'ASRL/dev/ttyUSB0::INSTR'

power_range = [-3,-103]
power_points = 51#21
power_sleep = 30

integ_time = 0.5    #sec
fs = 100            #mhz
fft_points = 1024   
freq = 21.4
#freq = 10


##
##
##

powers = np.linspace(power_range[0], power_range[1], power_points)
gen = visa_generator(gen_name)

gen.set_freq_mhz(freq)
gen.set_power_dbm(power_range[0])
gen.turn_output_on()

client = apex_holo_client(zu_ip, cmd_port, data_port)
client.set_dft_size(fft_points)
time.sleep(0.5)
client.set_integration_time(integ_time)
time.sleep(0.5)
client.set_frequency_to_acquire(freq*1e6)


raw_data= []

stamps = np.zeros(powers.shape)
client.enable_correlator()

for i, power in enumerate(powers):
    start = time.time()
    stamps[i] = start
    gen.set_power_dbm(power)
    print(power)
    while((time.time()-start)<power_sleep):
        try:
            msg = client.data_sock.recv(1024)
            raw_data.append(msg)
        except:
            pass

gen.turn_output_off()
data = np.array([np.frombuffer(x, 'd') for x in raw_data])
data = data.reshape((-1,5))

##my stamps differs from the ones at the vector voltmeter
start = 0
stop = stamps[0]
sort_data = dict()
for i in range(len(stamps)):
    stop = stamps[i]
    mask = np.bitwise_and(data[:,4]>start, data[:,4]<stop)
    sort_data[str(powers[i])] = data[mask,:4]
    start = stamps[i]

###alternative version, we look where the derivative is negative
diff = np.diff(10*np.log10(data[:,0]))  ##HERE I SHOULD USE THE PORT THAT IS BEING CHANGING
pow_diff = powers[1]-powers[0]
ind = np.where(diff< (-(abs(pow_diff)-1)))[0]   ##3HERE I GAVE A 1dB for sloopynes

start =0
sort_data2 = dict()
avg_pow_diff = np.zeros(len(ind))
std_pow_diff = np.zeros(len(ind))
avg_ang_diff = np.zeros(len(ind))
std_ang_diff = np.zeros(len(ind))
for i in range(len(ind)):
    data_frame = data[start:ind[i],:4]
    sort_data2[str(powers[i])] =data_frame
    start = ind[i]

    pow_diff = 10*(np.log10(data_frame[3:,0])-np.log10(data_frame[3:,1]))
    avg_pow_diff[i] = np.mean(pow_diff)
    std_pow_diff[i] = np.std(pow_diff)
    phase = np.rad2deg(np.angle(data_frame[3:,2]+1j*data_frame[3:,3]))
    avg_ang_diff[i] = np.mean(phase)
    std_ang_diff[i] = np.std(phase)


##there is a weird stuff here.. the std of the phase is too good







