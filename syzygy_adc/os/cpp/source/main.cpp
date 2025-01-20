#include "../includes/Snapshot.h"
#include "../includes/SCPI_server.h"
#include <iostream>
#include <vector>
#include <string>
#include <mutex>
#include <thread>
#include <chrono>

const int adc_samples {1024};
const int ms_sleep {100};

const axi_lite_reg axil_reg {
    .page_offset = (0xA0008000/PAGE_SIZE)*PAGE_SIZE,
    .internal_offset =0xA0008000%PAGE_SIZE,
    .kernel_size = 32*1024,
    .fpga_addr = 1024
};

const axi_lite_reg axil_bram {
    .page_offset = (0xA0000000/PAGE_SIZE)*PAGE_SIZE,
    .internal_offset =0xA0000000%PAGE_SIZE,
    .kernel_size = 32*1024,
    .fpga_addr = 1024
};


const std::string binfile {"/home/root/bitfiles/holo_test/fpga.bin"};
const std::string dev_mem {"/dev/mem"};


//network parameters
//std::string_view ip {"192.168.7.2"};
std::string_view ip {"10.0.6.229"};
int port_cmd {12234}, port_data {12235};

int recv_len {128};

std::vector<std::string_view> scpi_cmds {
    "HOLO:ZUBOARD:GET_SNAPSHOT",
};


int main(){
    int64_t stamp {0};
    std::vector<int16_t> adc0(adc_samples+5);
    std::vector<int16_t> adc1(adc_samples+5);
    adc0[adc_samples+4] = 0;
    adc1[adc_samples+4] = 1;
    Snapshot fpga = Snapshot(binfile, dev_mem,
            axil_reg, axil_bram);
    SCPI_server cmd_serv(ip, port_cmd);
    std::string recv_msg {};
    std::string out_msg {};
    std::vector<int> socket_index {0};
    std::vector<char> recv_buffer(recv_len);
    int recv_size {0}, func_index {-1};
    float arg {-1};
    bool samples_took {false};

    while(1){
        samples_took = false;
        cmd_serv.TcpServer::checkClientAvailable(socket_index);
        for(int i=socket_index.size()-1; i>-1; --i){
            recv_size = cmd_serv.TcpServer::recvSocketData<char>(recv_buffer, recv_len,
                    socket_index[i]);
            recv_msg = recv_buffer.data();
            func_index = cmd_serv.parse_recv_msg(recv_msg, arg, scpi_cmds);
            switch(func_index){
                case 0:{ //get the snapshot data
                    if(~samples_took){
                        //just take the data if necessary
                        fpga.get_snapshot(adc0, adc1,adc_samples, ms_sleep);
                        stamp = std::chrono::duration_cast<std::chrono::microseconds>(
                            std::chrono::system_clock::now().time_since_epoch()).count();
                        for(int j=0; j<4; ++j){
                            adc0[adc_samples+j] = static_cast<int16_t>((stamp>>(16*j)) & 0xffff);
                            adc1[adc_samples+j] = static_cast<int16_t>((stamp>>(16*j)) & 0xffff);
                        }
                        samples_took = true;
                    }
                    //now I have to send the data to the socket 
                    cmd_serv.TcpServer::sendSocketData(adc0, i);
                    cmd_serv.TcpServer::sendSocketData(adc1, i);
                }
                default:{
                    std::cout << "not recognized command :(\n";
                }
            }
        }
    }
}

