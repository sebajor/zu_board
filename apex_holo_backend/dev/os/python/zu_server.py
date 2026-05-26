import mmap, struct
import subprocess
import time
import numpy as np
import socket
import datetime


##hyperparameters
binfile= '/home/root/apex_holo/fpga.bin'
dev_mem_file = '/dev/mem'
ip = '192.168.7.2'
port = 1234

dft_size = 1024#4096
k = 102
acc_len = 2**16 ##10
twidd_pt = 14
fs = 100*1e6

ring_limit_addr = int(2**14/5)*5


axil_reg = { 'offset': 0xA0008000,
             'kernel_size': 32*2**10,   #32k
             'fpga_addr': 2**10,
             'data_width': 4,           #bytes
             'data_type': 'I'
        }

adc_bram =  {'offset': 0xA0000000,
             'kernel_size': 32*2**10,   #32k
             'fpga_addr': 2**10,
             'data_width': 4,           #bytes
             'data_type': 'I'
                     }

twiddle_factors =  {'offset': 0xA0010000,
             'kernel_size': 32*2**10,   #32k
             'fpga_addr': 2**10,
             'data_width': 4,           #bytes
             'data_type': 'I'
                     }

ring_buffer = {'offset': 0xA0080000,
             'kernel_size': 512*2**10,   #32k
             'fpga_addr': 2**14,
             'data_width': 8,           #bytes
             'data_type': 'q'
            }

registers = [axil_reg, adc_bram, twiddle_factors, ring_buffer]


## axil_reg[0]:
##      0:reset
##      1:enable_adc
##      2:enable_bram
##      3:enable_correaltor
##      4:correlator_ack
##      5:disable_ring_buff (by default is enabled)
## axil_reg[1]: acc_len
## axil_reg[2]: delay_line
##
## axil_reg[3]: FREE
##
## axil_reg[4]:
##      0:correlator_valid 
##      1:correlator_ack_error
##      2:mmcm_locked
##      3:clk_align_frame_valid
##      4-7: bitslip
##
## axil_reg[5] : pow0_0
## axil_reg[6] : pow0_1
## axil_reg[7] : pow1_0
## axil_reg[8] : pow1_1
## axil_reg[9] : ab_real_0
## axil_reg[10]: ab_real_1
## axil_reg[11]: ab_imag_0
## axil_reg[12]: ab_imag_1
## axil_reg[13]: ring_buffer_pointer
## axil_reg[14]: first stamp (32bits!)
##

##M00: adc data
##M01: axil reg
##M02: dft twiddle factor
##M03: none
##M04: ring_buffer


##bitwise operations

def set_bit(data, bit_ind):
    """
    set the bit_ind but dont touch the others
    """
    data |= (1<<bit_ind)
    return data

def clear_bit(data, bit_ind):
    """
    clear the bit_ind but dont touch the others
    """
    data &= ~(1<<bit_ind)
    return data

def flip_bit(data, bit_ind):
    """
    change the bit_ind status
    """
    data ^= (1<<bit_ind)
    return data

def get_bit(data, bit_ind):
    bit = data & (1<<bit_ind)
    return bit



class holo_backend_server():

    def __init__(self, binfile, dev_mem_file, registers):
        self.axil_reg_info = registers[0]
        self.adc_bram_info = registers[1]
        self.twiddle_info = registers[2]
        self.ring_info = registers[3]
        print("Programming FPGA")
        result = subprocess.run(['fpgautil', '-b', binfile], capture_output=True)
        print(result.stdout)
        if(not 'BIN FILE loaded through FPGA manager successfully' in str(result.stdout)):
            exit
        self.fpga_mem = open(dev_mem_file, 'r+b')

        self.reg = mmap.mmap(self.fpga_mem.fileno(), self.axil_reg_info['kernel_size'], offset=self.axil_reg_info['offset'])
        self.adc_bram = mmap.mmap(self.fpga_mem.fileno(), self.adc_bram_info['kernel_size'], offset=self.adc_bram_info['offset'])
        self.twiddle_bram = mmap.mmap(self.fpga_mem.fileno(), self.twiddle_info['kernel_size'], offset=self.twiddle_info['offset'])
        self.ring_bram = mmap.mmap(self.fpga_mem.fileno(), self.ring_info['kernel_size'], offset=self.ring_info['offset'])

        self.lim_addr = ring_limit_addr

        self.init_stamp, self.init_counter = self.get_first_stamp()
        self.data_buffer = []
        self.read_pointer = 0

        #reset te system and enable adc
        self.reg[0:axil_reg['data_width']] = struct.pack(axil_reg['data_type'], 1)
        time.sleep(0.1)
        self.reg[0:axil_reg['data_width']] = struct.pack(axil_reg['data_type'], 0)
        ##enable the adc
        self.reg[0:axil_reg['data_width']] = struct.pack(axil_reg['data_type'], 2)

    def close(self):
        self.fpga_mem.close()


    def get_first_stamp(self):
        curr_stamp = time.time()
        fpga_counter = struct.unpack(self.axil_reg_info['data_type'],self.reg[14*4:15*4])[0]
        return curr_stamp, fpga_counter

    def counter2stamp(self, count):
        count_diff = count-self.init_counter
        stamp = self.init_stamp+count_diff/fs
        return stamp

    def get_write_pointer(self):
        wr_ptr = struct.unpack(self.axil_reg_info['data_type'], self.reg[13*4:14*4])[0]
        return wr_ptr

    def read_ring_buffer(self):
        """
        The output of the data is: aa, bb, corr_re, corr_im, stamp. This does repeat each 
        5 addresses up to the limit of the ring buffer
        """
        wr_ptr = struct.unpack(self.axil_reg_info['data_type'], self.reg[13*4:14*4])[0]
        size = wr_ptr-self.read_pointer
        data = []
        if(size==0):
            return -1
        """
        ##struct cries about the size too
        if(size<0):
            #counter ovf
            data = struct.unpack(self.ring_info['data_type'], self.ring_bram[self.read_pointer*
                                                                    self.ring_info['data_width']:
                                                                    self.lim_addr*self.ring_info['data_width']])
            self.read_pointer = 0
        data += struct.unpack(self.ring_info['data_type'], self.ring_bram[self.read_pointer*
                                                                    self.ring_info['data_width']:
                                                                    wr_ptr*self.ring_info['data_width']])
        """
        if(size<0):
            #conuter ovf
            data = np.frombuffer(self.ring_bram[self.read_pointer*self.ring_info['data_width']: self.lim_addr*self.ring_info['data_width']],
                                 self.ring_info['data_type']).tolist()
            self.read_pointer = 0
        data += np.frombuffer(self.ring_bram[self.read_pointer*self.ring_info['data_width']: wr_ptr*self.ring_info['data_width']],
                                 self.ring_info['data_type']).tolist()
        self.read_pointer = wr_ptr
        self.data_buffer+=data
        return data



    def get_snapshot(self, sleep=0.1):
        ##read the previous value
        prev = struct.unpack(self.axil_reg_info['data_type'], self.reg[:4])[0]
        msg = clear_bit(prev, 2)
        self.reg[0:4] = struct.pack(self.axil_reg_info['data_type'], msg)
        msg = set_bit(prev, 2)
        self.reg[0:4] = struct.pack(self.axil_reg_info['data_type'], msg)
        ##make a rising edge in the enable bit
        time.sleep(sleep)
        data = np.frombuffer(self.adc_bram[:self.adc_bram_info['fpga_addr']*self.adc_bram_info['data_width']],
                                       'h')
        adc0 = data[::2]
        adc1 =  data[1::2]
        return adc0, adc1

    def set_acc_len(self, acc_len):
        self.reg[1*4:2*4] = struct.pack(self.axil_reg_info['data_type'], acc_len)
    
    def set_dft_len(self, dft_len):
        self.reg[2*4:3*4] = struct.pack(self.axil_reg_info['data_type'], dft_len)

    def compute_twiddle_factors(self, dft_len, k):
        n = np.arange(dft_len)
        twidd = np.exp(-1j*2*np.pi*n*k/dft_len)
        return twidd


    def configure_correlator(self, dft_len, k, twidd_binpt):
        ##first check that the dft len is less than the max value
        if(dft_len> self.twiddle_info['fpga_addr']):
            print("DFT len bigger than the address of the bram")
            return 1
        twidd = self.compute_twiddle_factors(dft_len, k)
        aux = np.array([twidd.real, twidd.imag]).T.flatten()   #check order !!! im is the low, re is high
        aux = (aux*2**twidd_binpt).astype(int)
        aux_bin = struct.pack(str(2*dft_len)+'i', *(aux))
        aux2 = struct.unpack(str(2*dft_len)+'I', aux_bin)
        self.twiddle_bram[:4*2*dft_len] = aux_bin
        self.set_dft_len(int(dft_len-1))

    def enable_correlator(self):
        prev = struct.unpack(self.axil_reg_info['data_type'], self.reg[:4])[0]
        msg = set_bit(prev, 3)
        self.reg[0:4] = struct.pack(self.axil_reg_info['data_type'], msg)




