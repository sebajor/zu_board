import mmap, struct
import subprocess
import time
import numpy as np

filename = '/home/root/bitfiles/blink_led/fpga.bin'
dev_mem_file = '/dev/mem'

axil_reg = { 'offset': 0xA1100000,
             'kernel_size': 4*2**10,   #32k
             'fpga_addr': 2**10,
             'data_width': 4,           #bytes
             'data_type': 'I'
        }

#axil_reg[0] = bram_data
#axil_reg[1] = bram_addr
#axil_reg[2] = bram_we
#axil_reg[3] = leds

axil_bram = {'offset': 0xA0000000,
             'kernel_size': 32*2**10,   #32k
             'fpga_addr': 2**10,
             'data_width': 4,           #bytes
             'data_type': 'I'
        }

##first we are going to program the fpga
print("Programming FPGA")
result = subprocess.run(['fpgautil', '-b', filename], capture_output=True)
if(not 'BIN FILE loaded through FPGA manager successfully' in str(result.stdout)):
    print(result.stdout)
    exit 

subprocess.run(['chmod', '777', dev_mem_file])

fpga_mem = open(dev_mem_file, 'r+b')

reg = mmap.mmap(fpga_mem.fileno(), axil_reg['kernel_size'], offset=axil_reg['offset'])
bram = mmap.mmap(fpga_mem.fileno(), axil_bram['kernel_size'], offset=axil_bram['offset'])


##write random stuffs using bram ports
print("Writing/read bram from axi ports")
data = np.random.randint(2**31, size=axil_bram['fpga_addr'])
##write the data into the bram
bram[:axil_bram['data_width']*axil_bram['fpga_addr']] = struct.pack(str(axil_bram['fpga_addr'])+axil_bram['data_type'],
                                              *data)

##read the data
read_data = np.frombuffer(bram[:axil_bram['data_width']*axil_bram['fpga_addr']],dtype=axil_bram['data_type'])

assert (read_data==data).all(), "Error writing/reading from bram interface"
print("Ok")

##now we write from the axilite register
print("Writing bram from FPGA port and reading through the PS")
reg[axil_reg['data_width']:axil_reg['data_width']*2] = struct.pack(axil_reg['data_type'], 0)   #start at addr0
reg[axil_reg['data_width']*2:axil_reg['data_width']*3] = struct.pack(axil_reg['data_type'], 1) #enable writing


data = np.random.randint(2**31, size=axil_bram['fpga_addr'])
for i in range(axil_bram['fpga_addr']):
    reg[axil_reg['data_width']:axil_reg['data_width']*2] = struct.pack(axil_reg['data_type'], i)
    reg[axil_reg['data_width']*0:axil_reg['data_width']*1] = struct.pack(axil_reg['data_type'], data[i])

##now read the data from the bram
read_data = np.frombuffer(bram[:axil_bram['data_width']*axil_bram['fpga_addr']],dtype=axil_bram['data_type'])


assert (read_data==data).all(), "Error reading from bram interface or writing from register"
print("OK")


