import numpy as np
import matplotlib.pyplot as plt
import datetime


def plot_adc(filename):
    dat = np.loadtxt('adc_data')
    spect = np.fft.fft(dat, axis=1)
    fig, axes = plt.subplots(2,1)
    freq = np.linspace(0,100,1024)
    max_val0 = np.argmax(np.abs(spect[0,5:]))+5
    max_val1 = np.argmax(np.abs(spect[1,5:]))+5
    print("Max value at channel %i %i"%(max_val0,max_val1))
    axes[0].plot(dat[0,:])
    axes[0].plot(dat[1,:])
    axes[1].plot(freq, 20*np.log10(np.abs(spect[0,:])))
    axes[1].plot(freq, 20*np.log10(np.abs(spect[1,:])))
    plt.show()


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

def plot_collected_data(filename):
    data, stamps = quick_parse_data(filename)
    fig, axes = plt.subplots(2,1, sharex=1)
    pow_diff = 10*(np.log10(data[:,1])-np.log10(data[:,0]))
    phase_diff = np.rad2deg(np.angle(data[:,2]+1j*data[:,3]))
    timestamps = [datetime.datetime.fromtimestamp(x) for x in stamps]
    axes[0].plot(timestamps, pow_diff, color='darkblue')
    axes[1].plot(timestamps, phase_diff, color='darkred')
    plt.show()
    










