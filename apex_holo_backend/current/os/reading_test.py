from zu_server import *

asd =holo_backend_server(binfile, dev_mem_file, registers)

asd.set_acc_len(acc_len)
asd.configure_correlator(dft_size, k, twidd_pt)
asd.enable_correlator()

count = 0
iters = 100
dat = []
while(count<iters):
    if(asd.check_data_available()):
        dat.append(asd.get_reg_data())
        asd.ack_data()
        count+=1
        print(count)
    else:
        pass

print(asd.check_ack_error())


pow0_data, pow1_data = asd.get_power()
corr_re, corr_im = asd.get_corr()

        
    








