import mmap, struct
import subprocess
import time, datetime
import numpy as np
import socket

###
### This code must be run at the zuboard and respond to SCPI commands sent by the
### client to send the data
###

###
### Hyperparameters
###

filename = '/home/root/bitfiles/adc_test/fpga.bin'
dev_mem_file = '/dev/mem'
ip = '192.168.7.2'
port = 1234


## axil_reg: M01
axil_reg = { 'offset': 0xA0008000,
             'kernel_size': 32*2**10,   #32k
             'fpga_addr': 2**10,
             'data_width': 4,           #bytes
             'data_type': 'I'
        }
## axil_reg[0]:
##      0: reset
##      1:enable_adc
##      2:enable_bram
## axil_reg[1]:
##      0-3:bitslip
##      4: clk_align_frame_valid
##      5:mmcm_locked
##      

adc_bram =  {'offset': 0xA0000000,
             'kernel_size': 32*2**10,   #32k
             'fpga_addr': 2**10,
             'data_width': 4,           #bytes
             'data_type': 'I'
                     }


class adc_snapshot():

    def __init__(self, filename, dev_mem_file, axil_reg, adc_bram):
        print("Programming FPGA")
        result = subprocess.run(['fpgautil', '-b', filename], capture_output=True)
        print(result.stdout)
        if(not 'BIN FILE loaded through FPGA manager successfully' in str(result.stdout)):
            exit 
        self.fpga_mem = open(dev_mem_file, 'r+b')

        self.reg = mmap.mmap(self.fpga_mem.fileno(), axil_reg['kernel_size'], offset=axil_reg['offset'])
        self.bram = mmap.mmap(self.fpga_mem.fileno(), adc_bram['kernel_size'], offset=adc_bram['offset'])

        #reset te system and enable adc
        self.reg[0:axil_reg['data_width']] = struct.pack(axil_reg['data_type'], 1)
        time.sleep(0.1)
        self.reg[0:axil_reg['data_width']] = struct.pack(axil_reg['data_type'], 0)
        ##enable the adc
        self.reg[0:axil_reg['data_width']] = struct.pack(axil_reg['data_type'], 2)

        self.axil_reg_info = axil_reg
        self.bram_info = adc_bram

    def close(self):
        self.fpga_mem.close()

    def get_snapshot(self, _sleep=0.1):
        ##make a rising edge in the enable bit
        self.reg[0:4] = struct.pack(self.axil_reg_info['data_type'], 0b010)
        self.reg[0:4] = struct.pack(self.axil_reg_info['data_type'], 0b110)
        time.sleep(_sleep)
        data = np.frombuffer(self.bram[:self.bram_info['fpga_addr']*self.bram_info['data_width']],
                                       'H')
        adc0 = data[::2]-2**15 
        adc1 =  data[1::2]-2**15
        return adc0, adc1


##
def get_snapshot(fpga_intf, param):
    adc0, adc1 = fpga_intf.get_snapshot()
    return adc0.tobytes()+adc1.tobytes()



##server bullshit

def timestamp():
    return ("%s\n"%(datetime.datetime.now())).replace(" ","T")

## SCPI_cmd, function, last_value_requested, timestamp from previous cmd
SCPI_prefix = 'ZUBOARD:'
SCPI = [
        [SCPI_prefix+"GET_SNAPSHOT",      get_snapshot]
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
    fpga_intf = adc_snapshot(filename, dev_mem_file, axil_reg, adc_bram)
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

     
     


