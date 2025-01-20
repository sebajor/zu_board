from calandigital import visa_generator
import numpy as np
from calandigital.instruments.visa_generator import visa_generator
from zu_client import *
import time


filename = 'data'
zu_ip = '10.17.90.157'

gen1_name = 'TCPIP::10.17.89.229::INST'
gen2_name = 'TCPIP::10.17.90.143::INST'

power_range = [-3,-103]
power_points = 21
power_sleep = 10

ref_sweep = False
ref_power = [-3,3]
ref_points = 4

integ_time = 0.5    #sec
fs = 100            ##mhz
fft_points = 1024   
freq = 21.4         #mhz


k= np.round(freq/(fs/2/(fft_points-1)))
print("k= {:}".format(k))


##power time
pow_time = 5


##connect to the generators
gen_ref = visa_generator(gen1_name)
gen_sig = visa_generator(gen2_name)

powers = np.linspace(power_range[0], power_range[1], power_points)

gen_ref.set_freq_mhz(freq)
gen_sig.set_freq_mhz(freq)

gen_ref.set_power_dbm(ref_power[0])
gen_sig.set_power_dbm(powers[0])

gen_ref.turn_output_on()
gen_sig.turn_output_on()

client = apex_holo_client(zu_ip, cmd_port, data_port)
raw_data= []

stamps = np.zeros(powers.shape)

client.enable_correlator()
for i, power in enumerate(powers):
    start = time.time()
    stamps[i] = start
    gen_sig.set_power_dbm(power)
    print(power)
    while((time.time()-start)<pow_time):
        try:
            msg = client.data_sock.recv(1024)
            raw_data.append(msg)
        except:
            pass

gen_sig.turn_output_off()
gen_ref.turn_output_off()
data = np.array([np.frombuffer(x,'f') for x in raw_data])


