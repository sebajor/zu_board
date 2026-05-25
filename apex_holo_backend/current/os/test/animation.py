import matplotlib.pyplot as plt
import sys
sys.path.append('..')
from zu_client import *
import ipdb

zu_ip = '10.0.6.235'
points = 64


plt.ion()
fig, axes = plt.subplots(2,1)
data = np.zeros((3, points))

client = apex_holo_client(zu_ip, cmd_port, data_port)
client.enable_correlator()

line_pow0, = axes[0].plot([],[])
line_pow1, = axes[0].plot([],[])
line_phase, = axes[1].plot([],[])

axes[0].set_xlim(0,points)
axes[1].set_xlim(0,points)
axes[0].set_ylim(0,170)
axes[1].set_ylim(-180,180)


counter = 0
x_axis = np.arange(points)
fig.canvas.draw()
plt.show(block=False)
while(1):
    try:
        print(counter)
        msg = client.data_sock.recv(1024)
        dat = np.frombuffer(msg,'d').reshape((-1,5))
        data[0, counter:counter+dat.shape[0]] = 10*np.log10(dat[:,0])
        data[1, counter:counter+dat.shape[0]] = 10*np.log10(dat[:,1])
        data[2, counter:counter+dat.shape[0]] = np.angle(dat[:,2]+1j*dat[:,3])
        line_pow0.set_data(x_axis, data[0,:])
        line_pow1.set_data(x_axis, data[1,:])
        line_phase.set_data(x_axis, data[2,:])
        if((counter+dat.shape[0])>=points):
            counter = 0
        else:
            counter+= dat.shape[0]
        fig.canvas.draw()
        fig.canvas.flush_events()
    except:
        print('exception')
        pass


