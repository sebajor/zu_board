from zu_client import *
import numpy as np
import datetime
import time


time2save = 3   #hours
sampling = 20   #seconds

zu_ip = '10.0.6.88'
zu_port = 12234

filename = 'data'


##connect to the zuboard
zu = zu_client(zu_ip, zu_port)


start = time.time()
with open(filename, 'wb') as f:
    while(1):
        adc0, adc1 = zu.get_powers()
        corr = zu.get_correlation()
        data = np.hstack([time.time(), adc0, adc1, corr.real, corr.imag])
        #np.save(f, data)
        np.savetxt(f, data[np.newaxis], newline='\n')
        print('save data..')
        time.sleep(sampling)
        if(time.time()-start > time2save*60*60):
            break

print('finish to take data')
