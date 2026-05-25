import numpy as np
import datetime
from scipy.interpolate import interp1d
import argparse
import os, sys

###
### Note: To run this you should have obtained the timestamped telescope positions running the get_telpos.py over the mbfits
###

parser = argparse.ArgumentParser(
    description="Maps the timestamped data from the cornetoscopio to the holo1 files")

parser.add_argument("-fc" "--fc", dest="corneto_file", type=str, default="",
                    help="conetoscopio generated file", )
parser.add_argument("-fm" "--fm", dest="mbfit_pos", type=str, default="telescope_pos.txt",
                    help="timestamped telescope positions obtained from the mbfits file")
parser.add_argument("-cook", "--cook", dest="az_cook", type=float, default=0,
                    help="Cook offset to align the map")
parser.add_argument("-old_cal", "--old_cal", dest="old_cal", action="store_true",
                    help="If present then do the transformation to be compatible with the old HP voltmeter format")
parser.add_argument("-raw_pos", "--raw_pos", dest="raw_pos", action="store_true",
                    help="If present then returned the full scan, including the reposition of the antenna")
parser.add_argument("-hires", "--hires", dest='hires', action="store_true",
                    help="If present use the hires parameters, otherwise use the lores ones")




def quick_parse_data(filename):
    """
    Parse the data from the cornetoscopio.
    data[:,0]= A**2
    data[:,1]= B**2
    data[:,2] = real(A*conj(B))
    data[:,3] = imag(A*conj(B))
    """
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


if __name__ == '__main__':
    az_center = 37.8471044-0.01 ##cooked.. I see that is not centered.
    el_center = 12.89771944

    az_room = 0.06#0.12


    args = parser.parse_args()
    corneto_file = os.path.realpath(os.path.expanduser(args.corneto_file))
    telpos_file = os.path.realpath(os.path.expanduser(args.mbfit_pos))
    ##chech if the file 
    if(not (os.path.exists(corneto_file) and os.path.exists(telpos_file))):
        print("Either %s or %s dont exist"%(corneto_file, telpos_file))

    ##see if use the hires or lores parameters
    if(args.hires):
        az_size = 10800.0/3600+az_room
        el_size = 256*42/3600
    else:
        az_size = 5400/3600+az_room
        el_size = 128*42/3600


    data, stamp = quick_parse_data(corneto_file)
    t_stamp, az, el = np.loadtxt(telpos_file).T

    #mask out the data that does not belong to the map timestamp
    mask = np.zeros(stamp.shape, dtype=bool)
    mask[np.bitwise_and(stamp>np.min(t_stamp), stamp<np.max(t_stamp))] = True
    data = data[mask,:]
    stamp = stamp[mask]

    ##now we do interpolation in az and el separatly
    f_az = interp1d(t_stamp, az)#, kind='linear', bounds_error=False, fill_value=np.nan)
    f_el = interp1d(t_stamp, el)#, kind='linear', bounds_error=False, fill_value=np.nan)

    # evaluate at measurement times
    az_interp = f_az(stamp)
    el_interp = f_el(stamp)

    rel_pow = np.sqrt(data[:,1]/data[:,0])
    rel_phase = np.angle(np.conj(data[:,2]+1j*data[:,3]))

    #set the middle value
    az_interp -= az_center
    el_interp -= el_center
    #az_interp -= (az_interp.max()+az_interp.min())/2
    #el_interp -= (el_interp.max()+el_interp.min())/2
    if(args.old_cal):
        ##ill fake the rel phase just to match the old voltmeter
        dumptime = 0.002
        fs_old = 10*1e3
        rel_phase = np.rad2deg(rel_phase)*2**16/20*(dumptime*fs_old)/1e2

    if(args.raw_pos):
        dout = np.vstack([az_interp, el_interp, rel_pow, rel_phase]).T
        np.savetxt('full_map.holo1', dout)
   
    #here just consider the positive movement (ie discard the came back)
    mask = ((az_interp>-az_size/2)*(az_interp<az_size/2)).astype(bool)
    edges = np.where(np.diff(mask))[0]
    ##if everything is correct I should take multiples of 4
    pow_masked = []
    phase_masked = []
    el_masked = []
    az_masked = []
    ##for some reason we are out of 5 indices in the final map
    for i in range(len(edges)//4):
        init = edges[4*i]
        end = edges[4*i+1]

        az_subscan = az_interp[init:end]
        el_subscan = el_interp[init:end]
        pow_subscan = rel_pow[init:end]
        phase_subscan = rel_phase[init:end]

        pow_masked = np.hstack([pow_masked, pow_subscan])
        phase_masked = np.hstack([phase_masked, phase_subscan])
        el_masked = np.hstack([el_masked, el_subscan])
        az_masked = np.hstack([az_masked, az_subscan])

dout_masked = np.vstack([az_masked+float(args.az_cook), el_masked, pow_masked, phase_masked]).T
np.savetxt('masked_map.holo1', dout_masked)
