#include "../includes/apexHoloBackend.h"
#include "../includes/TcpSocket.h"
#include <signal.h>
#include <string>
#include <array>
#include <iostream>
#include <thread>
#include <mutex>


const int acc_len {16384};
const int k {102};
const int dft_size {1024};
const int twiddle_point {14};

std::string_view ip = "192.168.7.2";
int cmd_port = 1234;
int data_port = 1233;


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

const std::string binfile {"/root/bitfile"};
const std::string dev_mem {"/dev/mem"};

const std::vector<std::string> cmds {
    "ZUBOARD:SET_ACC",
    "ZUBOARD:GET_REG",
    "ZUBOARD:GET_SNAPSHOT",
    "ZUBOARD:GET_POWER",
    "ZUBOARD:CONFIG_CORRELATOR"
};


//simple test
int main(){
    std::array<float, 4> read_data {0};
    apexHoloBackend fpga = apexHoloBackend(binfile, dev_mem, axil_reg, axil_bram, snapshot_bram);
    fpga.set_accumulation(acc_len);
    fpga.upload_twiddle_factors(dft_size, k, twiddle_point);
    //fpga.enable_correlator();
    TcpSocket cmd_sock = TcpSocket();
    cmd_sock.bindListenSocket(ip, cmd_port);
    
    TcpSocket data_sock = TcpSocket();
    data_sock.bindListenSocket(ip, data_port);
    
    //I need to do this with multi threads..
    
    while(1){
        if(fpga.check_data_available()){
            fpga.get_register_data(read_data);
            fpga.acknowledge_data();
        }
        for(size_t i=0; i<read_data.size();++i){
            std::cout << read_data[i] << "\n";
        }
    }
return 1;
}

