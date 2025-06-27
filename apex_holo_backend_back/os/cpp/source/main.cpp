#include "../includes/SCPI_server.h"
#include <iostream>
#include <vector>
#include <array>

/*
 * this should be in header file!
 */
//fpga initial parameters
int acc_len {16384};
int k {102};
int dft_size {1024};
const int twiddle_point {14};


//configuration of the axilite devices

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

//
const std::string binfile {"/home/root/bitfiles/holo_test/fpga.bin"};
const std::string dev_mem {"/dev/mem"};

//communication settings
std::vector<int>  sock_index {0};
std::string_view ip {"localhost"};      //dont know why in the zuboard is not
                                        //recognizing the bare ip..but with localhost
                                        //it seems to be getting all the addresses
int port_cmd {12234}, port_data {12235};
int recv_len {128};



int main(){
    std::cout << "creating fpga obj\n";
    apexHoloBackend fpga = apexHoloBackend(binfile, dev_mem, 
            axil_reg, axil_bram, snapshot_bram);
    std::cout << "setting dft len\n";
    fpga.set_dft_len(dft_size);
    std::cout << "setting accumulation\n";
    fpga.set_accumulation(acc_len);
    std::cout << "uploading twiddle factors\n";
    fpga.upload_twiddle_factors(k, twiddle_point); 
    
    //scpi server 
    std::cout  << "creating the SCPI server\n";
    //btw dont use the fpga obj out of the SCPI_server!! when getting data uses
    //a thread to send the data to the data port, so it can mess with it
    SCPI_server scpi_server(ip, port_cmd, port_data, fpga);
    int recv_size {0};
    std::vector<char> recv_buffer {0};
    recv_buffer.reserve(recv_len);
    //to parse the message
    std::string recv_msg {};
    std::string cmds_out {"No cmd found\n"};
    
    std::cout << "Entering to the while true loop\n";

    while(1){
        scpi_server.cmd_server.checkClientAvailable(sock_index);
        for(int i=sock_index.size()-1; i>-1; --i){
            recv_size = scpi_server.cmd_server.recvSocketData<char>(recv_buffer, recv_len,
                    sock_index[i]);
            std::cout << "recv size " << recv_size << "\n";
            if(recv_size==0){
                //there was a deleted socket
                std::cout << "delete socket at "<<i << std::endl;
                continue;
            }
            recv_msg = recv_buffer.data();
            scpi_server.parse_recv_msg(recv_msg, cmds_out);
            //send the response
            recv_buffer.resize(cmds_out.size());
            recv_buffer.assign(cmds_out.data(), cmds_out.data()+cmds_out.size());
            scpi_server.cmd_server.sendSocketData<char>(recv_buffer, sock_index[i]);
            recv_buffer.clear();
        }
    }
    return 1;
}
