import mmap, struct
import subprocess
import time
import numpy as np

###
### Just to test the signed conversion of the data that goes into the fpga
###

filename = '/home/root/bitfiles/correlator_1bin/fpga.bin'
dev_mem_file = '/dev/mem'


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


##M00: adc data
##M01: axil reg
##M02: dft twiddle factor
##M03: power data
##M04: corr data

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


print("Programming FPGA")
result = subprocess.run(['fpgautil', '-b', filename], capture_output=True)
if(not 'BIN FILE loaded through FPGA manager successfully' in str(result.stdout)):
    print(result.stdout)
    exit 

subprocess.run(['chmod', '777', dev_mem_file])

fpga_mem = open(dev_mem_file, 'r+b')

reg = mmap.mmap(fpga_mem.fileno(), axil_reg['kernel_size'], offset=axil_reg['offset'])
bram_adc = mmap.mmap(fpga_mem.fileno(), adc_bram['kernel_size'], offset=adc_bram['offset'])

##first we reset this shit
reg[0:axil_reg['data_width']] = struct.pack(axil_reg['data_type'], 1)
time.sleep(0.1)
reg[0:axil_reg['data_width']] = struct.pack(axil_reg['data_type'], 0)
##enable the adc
reg[0:axil_reg['data_width']] = struct.pack(axil_reg['data_type'], 2)
time.sleep(0.5)
reg[0:axil_reg['data_width']] = struct.pack(axil_reg['data_type'], 0b110)
time.sleep(0.5)
data = np.frombuffer(bram_adc[:adc_bram['fpga_addr']*adc_bram['data_width']], 'h')
#adc0 = data[::2]
#adc1 = data[1::2]

np.savetxt('data',data)

