#include "../includes/apexHoloBackend.h"
#include "../includes/SCPI_server.h"
#include <iostream>
#include <string>
#include <vector>
#include <mutex>
#include <atomic>
#include <thread>
#include <chrono>
#include <iomanip>	//just to print with full presicion


//fpga initial parameters
int acc_len {16384*3};		//aprox 0.5s = 3*16384*dft_size/(100*1e6)
//int acc_len {16384};		//aprox 0.125s
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

//network parameters
//std::string_view ip {"192.168.7.2"};
std::string_view ip {"0.0.0.0"};
int port_cmd {12234}, port_data {12235};

int recv_len {128};

//scpi commands
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



//send message size
const int send_msg_size = 4;

//variable to be shared between threads
std::mutex mut;
std::atomic<int> data_flag = 0;

void data_thread(apexHoloBackend &fpga){
    std::cout << "starting data thread at "<< ip << " "<<port_data <<"\n";
    TcpServer data_serv(ip, port_data);
    std::vector<int> sock_index {};
    std::vector<char> recv_buffer {0};
    recv_buffer.reserve(recv_len);
    int recv_size {0};
    int64_t stamp {0};

    std::array<double, 4> read_data;
    std::vector<double> send_msg(send_msg_size*5);// = {0};
    //send_msg.reserve(send_msg_size*4);
    std::cout << send_msg_size << " " << send_msg.size() << "\n";
    int msg_words = 0;

    while(1){
        data_serv.checkClientAvailable(sock_index, 5);
        for(int i=sock_index.size()-1; i>-1; --i){
            //if the recv_size is zero the function internally drop the socket
            recv_size = data_serv.recvSocketData<char>(recv_buffer, recv_len,
                                                        sock_index[i]);
        }
        if(data_flag){
            mut.lock();
            if(fpga.check_data_available()){
                fpga.get_register_data(read_data);
                fpga.acknowledge_data();
		stamp = std::chrono::duration_cast<std::chrono::microseconds>(
				std::chrono::system_clock::now().time_since_epoch()).count();
                for(int i=0; i<4; ++i){
                    send_msg[i+msg_words*5] = read_data[i];
		    //std::cout << read_data[i] << " ";
                }
		send_msg[4+msg_words*5] = static_cast<double>(stamp)/1e6;
		//std::cout << "\n";
                msg_words+=1;
                if(msg_words==(send_msg_size)){
		    std::cout << "debug print\n";
		    for(int j=0; j<send_msg.size(); ++j)
		        std::cout << std::setprecision(15) << send_msg[j] << " ";
		    std::cout << "\n";
                    
		    std::cout << "sending data\n";
                    for(int j=1; j< data_serv.fds.size(); ++j){
                        data_serv.sendSocketData<double>(send_msg, j);
                    }
		    msg_words=0;
                }
            }
            mut.unlock();
        }
    }
}




int main(){
    std::array<double, 4> read_data {};
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
    
    //cmds server
    SCPI_server cmd_serv(ip, port_cmd);
    std::vector<int> socket_index {0};
    int recv_size {0};
    std::vector<char> recv_buffer(recv_len);
    std::string recv_msg {};
    std::string out_msg {"No cmd found\n"};
    float arg = -1;
    int func_index = -1;

    //data_thread(fpga);
    std::thread t_data(data_thread, std::ref(fpga));

    
    //mut.lock();
    //fpga.enable_correlator();
    //data_flag = 1;
    //mut.unlock();
    while(1){
        cmd_serv.TcpServer::checkClientAvailable(socket_index);
        for(int i=socket_index.size()-1; i>-1; --i){
            recv_size = cmd_serv.TcpServer::recvSocketData<char>(recv_buffer, recv_len,
                    socket_index[i]);
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
                default:{
                    std::cout << "non know message\n";
                    break;
                        }
            }


        }
    }
    /*
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
    */
    std::cout << "asdqwkeq\n";
    return 1;
}
