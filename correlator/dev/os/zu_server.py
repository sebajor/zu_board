import mmap, struct
import subprocess
import time
import numpy as np
import socket
import datetime

##hyperparameters
binfile= '/home/root/bitfiles/correlator/fpga.bin'
dev_mem_file = '/dev/mem'
ip = '10.0.6.88'
port = 1234

dft_size = 1024
acc_len = 2**16 ##10
twidd_pt = 14


axil_reg = { 'offset': 0xA0000000,
             'kernel_size': 64*2**10,   #32k
             'fpga_addr': 2**10,
             'data_width': 4,           #bytes
             'data_type': 'I'
        }


r11_bram = {'offset': 0xA0010000,
            'kernel_size': 64*2**10,    #64k
            'fpga_addr': 2**10,
            'data_width': 8,
            'data_type':'q'
        }



r22_bram = {'offset': 0xA0020000,
            'kernel_size': 64*2**10,    #64k
            'fpga_addr': 2**10,
            'data_width': 8,
            'data_type':'q'
        }

r12_bram = {'offset':  0xA0040000,
            'kernel_size': 64*2**10,    #64k
            'fpga_addr': 2**11,
            'data_width': 8,
            'data_type':'q'
        }




adc_bram =  {'offset': 0xA0060000,
             'kernel_size': 32*2**10,   #32k
             'fpga_addr': 2**10,
             'data_width': 4,           #bytes
             'data_type': 'I'
                     }


registers = [axil_reg, r11_bram, r22_bram, r12_bram]

## axil_reg[0]:
##      0:reset
##      1:enable_adc
##      2:enable_bram
##      3:enable_correaltor
##      4:correlator_ack
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
##

##M00: axil_reg 
##M01: r11
##M02: r22
##M03: r12 (imag, real)
##M04: 


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


class correlator():

    def __init__(self, binfile, dev_mem_file, registers):
        self.axil_reg_info = registers[0]
        self.r11_info = registers[1]
        self.r22_info = registers[2]
        self.r12_info = registers[3]
        print("Programming FPGA")
        result = subprocess.run(['fpgautil', '-b', binfile], capture_output=True)
        print(result.stdout)
        if(not 'BIN FILE loaded through FPGA manager successfully' in str(result.stdout)):
            exit
        self.fpga_mem = open(dev_mem_file, 'r+b')

        self.reg = mmap.mmap(self.fpga_mem.fileno(), self.axil_reg_info['kernel_size'], offset=self.axil_reg_info['offset'])
        self.r11_bram = mmap.mmap(self.fpga_mem.fileno(), self.r11_info['kernel_size'], offset=self.r11_info['offset'])
        self.r22_bram = mmap.mmap(self.fpga_mem.fileno(), self.r22_info['kernel_size'], offset=self.r22_info['offset'])
        self.r12_bram = mmap.mmap(self.fpga_mem.fileno(), self.r12_info['kernel_size'], offset=self.r12_info['offset'])

        #reset te system and enable adc
        self.reg[0:axil_reg['data_width']] = struct.pack(axil_reg['data_type'], 1)
        time.sleep(0.1)
        self.reg[0:axil_reg['data_width']] = struct.pack(axil_reg['data_type'], 0)
        ##enable the adc
        self.reg[0:axil_reg['data_width']] = struct.pack(axil_reg['data_type'], 2)

    def close(self):
        self.fpga_mem.close()

    def enable_correlator(self):
        prev = struct.unpack(self.axil_reg_info['data_type'], self.reg[:4])[0]
        msg = set_bit(prev, 3)
        self.reg[0:4] = struct.pack(self.axil_reg_info['data_type'], msg)

    def set_acc_len(self, acc_len):
        self.reg[1*4:2*4] = struct.pack(self.axil_reg_info['data_type'], acc_len)


    def get_r11(self):
        data = np.frombuffer(self.r11_bram[:self.r11_info['fpga_addr']*self.r11_info['data_width']], 'q')
        return data

    def get_r12(self):
        data = np.frombuffer(self.r12_bram[:self.r12_info['fpga_addr']*self.r12_info['data_width']], 'q')
        return data

    def get_r22(self):
        data = np.frombuffer(self.r22_bram[:self.r22_info['fpga_addr']*self.r22_info['data_width']], 'q')
        return data




def bit_reverse_indices(n):
    """Return array of bit-reversed indices for 0..n-1."""
    bits = int(np.log2(n))
    indices = np.arange(n)
    reversed_indices = np.array([
        int(f"{i:0{bits}b}"[::-1], 2) for i in indices
    ])
    return reversed_indices

def get_powers(fpga_intf, param):
    r11 = fpga_intf.get_r11()
    r22 = fpga_intf.get_r22()
    ind = bit_reverse_indices(1024)
    return r11[ind].tobytes()()+r22[ind].tobytes()()

def get_correlation(fpga_intf, param):
    r12 = fpga_intf.get_r12()
    r12_r = r12[::2]
    r12_i = r12[1::2]
    ind = bit_reverse_indices(1024)
    return r12_r[ind].tobytes()()+r12_i[ind].tobytes()()


def set_accumulation(fpga_intr, param):
    value = int(param.split(' ')[1])
    fpga_intf.set_acc_len(value)
    return "ok".encode()

def enable_corr(fpga_intf, param):
    fpga_intf.enable_correlator()




def timestamp():
    return ("%s\n"%(datetime.datetime.now())).replace(" ","T")


SCPI_prefix = 'ZUBOARD:'
SCPI = [
        [SCPI_prefix+"GET_POW",           get_powers],
        [SCPI_prefix+"GET_CORR",            get_correlation],
        [SCPI_prefix+"SET_ACC",             set_accumulation],
        [SCPI_prefix+"ENABLE_CORR",         enable_corr],
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
    fpga_intf = holo_backend_server(binfile, dev_mem_file, registers)
    fpga_intf.set_acc_len(acc_len)
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

