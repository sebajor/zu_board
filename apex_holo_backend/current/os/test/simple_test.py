import numpy as np
import sys
sys.path.append('../')
from zu_client import *

filename = 'data'
zu_ip = '10.0.6.219'
iters = 10


client = apex_holo_client(zu_ip, cmd_port, data_port)
raw_data= []
client.enable_correlator()
count = 0
while(count < iters):
    try:
        msg = client.data_sock.recv(1024)
        raw_data.append(msg)
        count +=1
    except:
        pass

data = np.array([np.frombuffer(x) for x in raw_data]).reshape((-1,5))

