import numpy as np
import datetime
from scipy.interpolate import interp1d


def quick_parse_data(filename):
    f = open(filename, 'rb')
    stamp = np.frombuffer(f.read(8), 'd')
    counter_init = np.frombuffer(f.read(8), 'Q')
    raw_data = f.read()
    ##check how many data frames we have
    frames = int(len(raw_data)/8/5)
    data = np.frombuffer(raw_data[:5*8*frames], 'q')   #aa,bb,ab_re,ab_im,count
    data = data.reshape((-1,5))
    ##convert from counter to timestamp
    fs = 100*1e6
    count_diff = (data[:,-1]-counter_init)
    stamps = stamp+count_diff/fs
    f.close()
    return data, stamps


#this are in deg
az_center = 37.8471044
el_center = 12.89771944

#this are in arcsec.. so we need to divide by 3600
hires_az_size = 10800.0/3600
lores_az_size = 5400/3600
hires_az_speed = 2.1/3600

hires_el_size = 256*42/3600
lores_el_size = 128*42/3600
hires_el_speed = 42/3600


data, stamp = quick_parse_data('maps')
#stamp -= 37 ##test tai to utc

t_stamp, az, el= np.loadtxt('telescope_pos.txt').T


mask = np.zeros(stamp.shape, dtype=bool)
mask[np.bitwise_and(stamp>np.min(t_stamp), stamp<np.max(t_stamp))] = True

##just see the data of the map
data = data[mask,:] 
stamp = stamp[mask]

f_az = interp1d(t_stamp, az)#, kind='linear', bounds_error=False, fill_value=np.nan)
f_el = interp1d(t_stamp, el)#, kind='linear', bounds_error=False, fill_value=np.nan)

# evaluate at measurement times
az_interp = f_az(stamp)
el_interp = f_el(stamp)


#set the middle value
az_interp -= (az_interp.max()+az_interp.min())/2
el_interp -= (el_interp.max()+el_interp.min())/2

rel_pow = np.sqrt(data[:,1]/data[:,0])
rel_phase = np.angle(np.conj(data[:,2]+1j*data[:,3]))

##ill fake the rel phase just to match the old voltmeter
dumptime = 0.002
fs_old = 10*1e3
rel_phase = np.rad2deg(rel_phase)*2**16/20*(dumptime*fs_old)/1e2


#az_interp += 0.19
dout = np.vstack([az_interp, el_interp, rel_pow, rel_phase]).T
np.savetxt('test_zu.holo1', dout)


#now Ill just take the positive movement on the az
pow_masked = []
phase_masked = []
el_masked = []
az_masked = []

mask = az_interp>-1.65
mask_edge = np.where(np.diff(mask))[0]
for i in range(len(mask_edge)//2):
    az_subscan = az_interp[mask_edge[2*i]:mask_edge[2*i+1]]
    el_subscan = el_interp[mask_edge[2*i]:mask_edge[2*i+1]]
    pow_subscan = rel_pow[mask_edge[2*i]:mask_edge[2*i+1]]
    phase_subscan = rel_phase[mask_edge[2*i]:mask_edge[2*i+1]]
    
    positive_mov = np.argmax(np.diff(el_subscan))

    pow_masked = np.hstack([pow_masked, pow_subscan[:positive_mov]])
    phase_masked = np.hstack([phase_masked, phase_subscan[:positive_mov]])
    el_masked = np.hstack([el_masked, el_subscan[:positive_mov]])
    az_masked = np.hstack([az_masked, az_subscan[:positive_mov]])

dout_masked = np.vstack([az_masked+0.19, el_masked, pow_masked, phase_masked]).T
np.savetxt('test2_zu.holo1', dout_masked)


    



