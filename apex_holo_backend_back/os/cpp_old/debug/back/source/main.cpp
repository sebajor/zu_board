#include "../includes/apexHoloBackend.h"
#include "../includes/SCPI_server.h"
#include <iostream>
#include <string>
#include <vector>


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

const std::string binfile {"/root/bitfile"};
const std::string dev_mem {"/dev/mem"};

//network parameters
std::string_view ip {"192.168.7.2"};
int port_cmd {1234}, port_data {1235};
std::vector<int> sock_index {0};

int recv_len {128};

//send message size
const int send_msg_size = 4;

void data_thread(apexHoloBackend &fpga){
    TcpServer data_serv(ip, port_data);


}


int main(){
    std::array<float, 4> read_data {};
    apexHoloBackend fpga = apexHoloBackend(binfile, dev_mem, 
            axil_reg, axil_bram, snapshot_bram);
    fpga.set_accumulation(acc_len);
    fpga.upload_twiddle_factors(dft_size, k, twiddle_point); 

    //configure the scpi server
    int recv_size {0};
    std::vector<char> recv_buffer {0};
    recv_buffer.reserve(recv_len);
    //to parse the message
    std::string recv_msg {};
    std::string out_msg {"No cmd found\n"};

    


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
}
