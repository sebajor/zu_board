#include "../includes/apexHoloBackend.h"
#include <iostream>
#include <string>


//fpga initial parameters
int acc_len {16384};
int k {102};
int dft_size {1024};
const int twiddle_point {14};


const axi_lite_reg axil_reg {
    .page_offset = (0xA0008000/PAGE_SIZE)*PAGE_SIZE,
    .internal_offset =0xA0008000%PAGE_SIZE,
    .kernel_size = 32*1024,
    .fpga_addr = 1024
};
//axil_bram, snapshot_bram

const axi_lite_reg axil_bram {
    .page_offset = (0xA0010000/PAGE_SIZE)*PAGE_SIZE,
    .internal_offset =0xA0010000%PAGE_SIZE,
    .kernel_size = 32*1024,
    .fpga_addr = 1024
};

const axi_lite_reg snapshot_bram {
    .page_offset = (0xA0000000/PAGE_SIZE)*PAGE_SIZE,
    .internal_offset =0xA0000000%PAGE_SIZE,
    .kernel_size = 32*1024,
    .fpga_addr = 1024
};

const std::string binfile {"/home/root/bitfiles/holo_test/fpga.bin"};
const std::string dev_mem {"/dev/mem"};


int main(){
    std::array<float, 4> read_data {};
    std::cout << "creating fpga obj\n";
    apexHoloBackend fpga = apexHoloBackend(binfile, dev_mem, 
            axil_reg, axil_bram, snapshot_bram);
    std::cout << "setting dft len\n";
    fpga.set_dft_len(dft_size);
    std::cout << "setting accumulation\n";
    fpga.set_accumulation(acc_len);
    std::cout << "uploading twiddle factors\n";
    fpga.upload_twiddle_factors(dft_size, k, twiddle_point); 
    std::cout << "enabling correlator\n";
    fpga.enable_correlator();
    while(1){
        if(fpga.check_data_available()){
            fpga.get_register_data(read_data);
            fpga.acknowledge_data();
            std::cout << "data available, erorr:"<< fpga.check_ack_error() << "\n";
            for(int i=0; i< read_data.size(); ++i){
                std::cout << read_data[i] <<"\n";
            }
        }
    }
    return 1;
}
