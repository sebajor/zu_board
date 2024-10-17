import mmap, struct
import subprocess
import time
import numpy as np
import socket
import datetime

##hyperparameters
binfile= '/home/root/bitfiles/correlator_1bin/fpga.bin'
dev_mem_file = '/dev/mem'
ip = '192.168.7.2'
port = 1234

dft_size = 1024
k = 102
acc_len = 10
twidd_pt = 14

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

power_bram=  {'offset': 0xA0018000,
             'kernel_size': 32*2**10,   #32k
             'fpga_addr': 2**10,
             'data_width': 4,           #bytes
             'data_type': 'I'
                     }

corr_bram=  {'offset': 0xA0020000,
             'kernel_size': 32*2**10,   #32k
             'fpga_addr': 2**10,
             'data_width': 4,           #bytes
             'data_type': 'i'
                     }

registers = [axil_reg, adc_bram, twiddle_factors, power_bram, corr_bram]

## axil_reg[0]:
##      0: reset
##      1:enable_adc
##      2:enable_bram
##      3:enable_correlator
## axil_reg[1]:
##      0-3:bitslip
##      4: clk_align_frame_valid
##      5:mmcm_locked
## axil_reg[2]: acc_len
## axil_reg[3]: delay_line

##M00: adc data
##M01: axil reg
##M02: dft twiddle factor
##M03: power data
##M04: corr data


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


class single_bin_correlator():

    def __init__(self, binfile, dev_mem_file, registers):
        """
        registers: [axil_reg, adc_bram. twiddle_factors, power_bram, corr_bram]
        """
        self.axil_reg_info = registers[0]
        self.adc_bram_info = registers[1]
        self.twiddle_info = registers[2]
        self.power_info = registers[3]
        self.corr_info = registers[4]
        print("Programming FPGA")
        result = subprocess.run(['fpgautil', '-b', binfile], capture_output=True)
        print(result.stdout)
        if(not 'BIN FILE loaded through FPGA manager successfully' in str(result.stdout)):
            exit 
        self.fpga_mem = open(dev_mem_file, 'r+b')

        self.reg = mmap.mmap(self.fpga_mem.fileno(), self.axil_reg_info['kernel_size'], offset=self.axil_reg_info['offset'])
        self.adc_bram = mmap.mmap(self.fpga_mem.fileno(), self.adc_bram_info['kernel_size'], offset=self.adc_bram_info['offset'])
        self.twiddle_bram = mmap.mmap(self.fpga_mem.fileno(), self.twiddle_info['kernel_size'], offset=self.twiddle_info['offset'])
        self.power_bram = mmap.mmap(self.fpga_mem.fileno(), self.power_info['kernel_size'], offset=self.power_info['offset'])
        self.corr_bram= mmap.mmap(self.fpga_mem.fileno(), self.corr_info['kernel_size'], offset=self.corr_info['offset'])

        #reset te system and enable adc
        self.reg[0:axil_reg['data_width']] = struct.pack(axil_reg['data_type'], 1)
        time.sleep(0.1)
        self.reg[0:axil_reg['data_width']] = struct.pack(axil_reg['data_type'], 0)
        ##enable the adc
        self.reg[0:axil_reg['data_width']] = struct.pack(axil_reg['data_type'], 2)
        

    def close(self):
        self.fpga_mem.close()
    
    def get_snapshot(self, _sleep=0.1):
        ##read the previous value
        prev = struct.unpack(self.axil_reg_info['data_type'], self.reg[:4])[0]
        msg = clear_bit(prev, 2)
        self.reg[0:4] = struct.pack(self.axil_reg_info['data_type'], msg)
        msg = set_bit(prev, 2)
        self.reg[0:4] = struct.pack(self.axil_reg_info['data_type'], msg)
        ##make a rising edge in the enable bit
        time.sleep(_sleep)
        data = np.frombuffer(self.adc_bram[:self.adc_bram_info['fpga_addr']*self.adc_bram_info['data_width']],
                                       'h')
        adc0 = data[::2]
        adc1 =  data[1::2]
        return adc0, adc1


    def set_acc_len(self, acc_len):
        self.reg[2*4:3*4] = struct.pack(self.axil_reg_info['data_type'], acc_len)
    
    def set_dft_len(self, dft_len):
        self.reg[3*4:4*4] = struct.pack(self.axil_reg_info['data_type'], dft_len)


    def get_power(self):
        data = self.power_bram[:self.power_info['fpga_addr']*self.power_info['data_width']]
        data = np.frombuffer(data, self.power_info['data_type'])
        power0 = data[::2]
        power1 = data[1::2]
        return power0, power1


    def get_corr(self):
        data = self.corr_bram[:self.corr_info['fpga_addr']*self.corr_info['data_width']]
        data = np.frombuffer(data, self.corr_info['data_type'])
        corr_re = data[::2]
        corr_im = data[1::2]
        return corr_re, corr_im

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
        




def get_snapshot(fpga_intf, param):
    adc0, adc1 = fpga_intf.get_snapshot()
    return adc0.tobytes()+adc1.tobytes()

def get_power(fpga_intf, param):
    power0,power1 = fpga_intf.get_power()
    return power0.tobytes()+power1.tobytes()

def get_corr(fpga_intf, param):
    corr_re, corr_im = fpga_intf.get_corr()
    return corr_re.tobytes()+corr_im.tobytes()

def config_correlator(fpga_intf, param):
    values = [int(x) for x in param.split(" ")[1].split(',')]
    fpga_intf.configure_correlator(values[0], values[1], values[2])
    return "ok".encode()
    
def set_accumulation(fpga_intr, param):
    value = int(param.split(' ')[1])
    fpga_intf.set_acc_len(value)
    return "ok".encode()


def timestamp():
    return ("%s\n"%(datetime.datetime.now())).replace(" ","T")

## SCPI_cmd, function, last_value_requested, timestamp from previous cmd
SCPI_prefix = 'ZUBOARD:'
SCPI = [
        [SCPI_prefix+"GET_SNAPSHOT",        get_snapshot],
        [SCPI_prefix+"GET_POWER",           get_power],
        [SCPI_prefix+"GET_CORR",            get_corr],
        [SCPI_prefix+"CONFIG_CORRELATOR",   config_correlator],
        [SCPI_prefix+"SET_ACC",             set_accumulation]
        ]
 

    
def execute_command(cmd, fpga_intf):
    data = cmd.upper().strip().split(" ")
    command = data[0]
    ans = command +" Error unknown command "+timestamp()
    param = ""
    if(len(data)>1):
        param = float(data[1])  ## should be always a float
    for scpi in SCPI:
        if(command == scpi[0]):
            cmd_ans = scpi[1](fpga_intf, param)
            print(len(cmd_ans))
            ans = cmd_ans
            break
    return ans




if __name__ == '__main__':
    fpga_intf = single_bin_correlator(binfile, dev_mem_file, registers)
    fpga_intf.set_acc_len(acc_len)
    fpga_intf.configure_correlator(dft_size, k, twidd_pt)
    fpga_intf.enable_correlator()
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((ip, port))
    while(1):
        try:
            data,addr = sock.recvfrom(1024)
            print(data)
            ans = execute_command(data.decode(), fpga_intf)
            sock.sendto(ans, addr)
        except KeyboardInterrupt:
            fpga_intf.close()
            sock.close()

