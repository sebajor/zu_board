from zu_server import *

#acc_len = 2**11 #to take 1 min to fill the ring buffer bram

integration = 2*1e-3
acc_len = int(integration/(dft_size/fs))
k = int(21.4*1e6/(fs/dft_size))

asd = holo_backend_server(binfile, dev_mem_file, registers)
asd.set_acc_len(acc_len)
asd.configure_correlator(dft_size, k, twidd_pt)
asd.enable_correlator()

with open("raw_data", "wb") as file:
    while(1):
        wr_ptr = struct.unpack(asd.axil_reg_info['data_type'], asd.reg[13*4:14*4])[0]
        size = wr_ptr-asd.read_pointer
        if(size==0):
            continue
        data = b""
        if(size<0):
            #conuter ovf
            data += asd.ring_bram[asd.read_pointer*asd.ring_info['data_width']: asd.lim_addr*asd.ring_info['data_width']]
                           
            asd.read_pointer = 0
        data += asd.ring_bram[asd.read_pointer*asd.ring_info['data_width']: wr_ptr*asd.ring_info['data_width']]
        asd.read_pointer = wr_ptr
        f.write(data)

