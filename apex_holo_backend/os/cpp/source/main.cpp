#include "../includes/SCPI_server.h"
#include "../includes/apexHoloBackend.h"
#include <iostream>
#include <string>
#include <signal.h>
#include <thread>
#include <mutex>
#include <atomic>
#include <array>


//network parameters
std::string_view ip {"192.168.7.2"};
int port_cmd {1234}, port_data {1235};
std::vector<int> sock_index {0};

int recv_len {128};

//send message size
const int send_msg_size = 4;

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

//scpi commands
std::vector<std::string_view> scpi_cmds {
    "HOLO:ZUBOARD:SET_ACC",
    "HOLO:ZUBOARD:GET_REG",
    "HOLO:ZUBOARD:GET_SNAPSHOT",
    "HOLO:ZUBOARD:ENABLE_CORR",
    "HOLO:ZUBOARD:DISABLE_CORR",
    "HOLO:ZUBOARD:SET_DFT_SIZE",
    "HOLO:ZUBOARD:SET_TWIDDLE",
};



//variables to be shared between the threads
std::mutex mut;
std::atomic<int> data_flag=0;

void data_thread(apexHoloBackend &fpga){
    TcpServer data_serv(ip, port_data);
    std::vector<int> sock_index {};
    std::vector<char> recv_buffer {0};
    int acc_len {128};
    recv_buffer.reserve(recv_len);
    int recv_size {0};
    
    std::array<float, 4> read_data;
    std::vector<float> send_msg = {0};
    send_msg.reserve(send_msg_size*4);
    int msg_words = 0;

    //this thread check if the send_data is true
    while(1){
        //check if someone wants to connect, this function also returns the indices
        //of the sockets that sent data or disconnect
        data_serv.checkClientAvailable(sock_index, 5); 
        for(int i=sock_index.size()-1; i>-1; --i){
            //if the recv_size is zero the function internally drop the socket
            recv_size = data_serv.recvSocketData<char>(recv_buffer, recv_len,
                                                        sock_index[i]);
        }
        //check if the enable signal is on
        if(data_flag){
            mut.lock();
            if(fpga.check_data_available()){
                fpga.get_register_data(read_data);
                //fpga.check_ack_error();
                fpga.acknowledge_data();
                for(int i=0; i<4; ++i){
                    send_msg[i+msg_words*4] = read_data[i];
                }
                msg_words+=1;
                if(msg_words==(send_msg_size-1)){
                    for(int j=1; j< data_serv.fds.size(); ++j){
                        data_serv.sendSocketData<float>(send_msg, j);
                    }

                }
            }
            mut.unlock();
        }
    }
}



int main(){
    //fpga initializing
    apexHoloBackend fpga = apexHoloBackend(binfile, dev_mem, 
            axil_reg, axil_bram, snapshot_bram);
    fpga.set_accumulation(acc_len);
    fpga.upload_twiddle_factors(dft_size, k, twiddle_point);
    //parameters for the 
    int recv_size {0};
    std::vector<char> recv_buffer {0};
    recv_buffer.reserve(recv_len);
    //to parse the message
    std::string recv_msg {};
    std::string out_msg {"No cmd found\n"};
    float arg = -1;
    int func_index = -1;
    
    SCPI_server cmd_serv(ip, port_cmd);

    std::thread t_data(data_thread, std::ref(fpga));

    while(1){
        cmd_serv.TcpServer::checkClientAvailable(sock_index);
        for(int i=sock_index.size()-1; i>-1; --i){
            recv_size = cmd_serv.TcpServer::recvSocketData<char>(recv_buffer, recv_len,
                    sock_index[i]);
            recv_msg = recv_buffer.data();
            func_index = cmd_serv.parse_recv_msg(recv_msg, arg, scpi_cmds);
            std::cout << "arg recv "<< arg<< "\n";
            switch(func_index){
                case 0:{//set acc
                    if(data_flag==0){
                        mut.lock();
                        fpga.set_accumulation(static_cast<int>(arg));
                        mut.unlock();
                        acc_len = static_cast<int>(arg);
                    }
                    break;
                }
                case 1:{
                    //get register; TODO
                    break;
                }
                case 2:{
                    //get snapshot; TODO
                    break;
                }
                case 3:{//enable corr
                    if(data_flag==0){
                        mut.lock();
                        fpga.enable_correlator();
                        data_flag = 1;
                        mut.unlock();
                    }
                    break;
                }
                case 4:{//disable corr
                    if(data_flag==1)
                        data_flag =0;
                    break;
                }
                case 5:{//set dft
                    if(data_flag==0){
                         mut.lock();
                         fpga.set_dft_len(static_cast<int>(arg));
                         mut.unlock();
                         dft_size = static_cast<int>(arg);
                    }
                    break;
                }
                case 6:{
                    if(data_flag==0){
                        mut.lock();
                        fpga.upload_twiddle_factors(dft_size, static_cast<int>(arg), twiddle_point); 
                        mut.unlock();
                    }
                }
            }
        }

    }
    return 0;
}


