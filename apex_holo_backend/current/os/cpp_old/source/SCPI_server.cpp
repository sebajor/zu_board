#include "../includes/SCPI_server.h"
#include "../includes/TcpSocket.h"
//#include "../includes/apexHoloBackend.h"
#include <iostream>
#include <string>
#include <charconv>
#include <random>
#include <chrono>
#include <iomanip>
#include <sstream>


int get_int_value_from_msg(std::string_view msg, int &value){
    size_t space = msg.find(" ");
    if(space!= std::string_view::npos){
        std::string_view s_arg = msg.substr(space+1);
        auto result = std::from_chars(s_arg.data(), s_arg.data()+s_arg.size(), value);
        if(result.ec != std::errc{}){
            return -1;
        }
        return 0;
    }
    else
        return -1;
}

SCPI_server::SCPI_server(std::string_view host, int port,
        std::string_view tcp_ip, int tcp_port, 
        const std::string &bin_file,const std::string &dev_mem,
        const axi_lite_reg &axil_reg, const axi_lite_reg &axil_bram,
        const axi_lite_reg &snapshot_bram, const axi_lite_reg &axi_ring, 
        int timeout, int sendsize, int recvsize, int reuse_addr){
    
    sock = UdpSocket::socket_config(-1, sendsize, recvsize, timeout, reuse_addr);
    std::cout << "opening UDP socket..";
    if(UdpSocket::bindSocket(sock, host, port))
        std::cout << "Failed to create the socket!\n";
    std::cout << "done\n";
    fpga_binfile = bin_file;
    fpga_dev_mem = dev_mem;

    axi_reg_info = axil_reg;    
    axi_bram_info = axil_bram;
    axi_snapshot_info = snapshot_bram;
    axi_ring_info = axi_ring;
    fpga.emplace(
            fpga_binfile,
            fpga_dev_mem,
            axi_reg_info,
            axi_bram_info,
            axi_snapshot_info,
            axi_ring_info
            );
    std::cout << "scpi constructor done\n";
}

SCPI_server::~SCPI_server(){
    UdpSocket::closeSocket(this->sock);
    if(fpga)
        fpga.reset();
    stream_running = false;
    if(worker.joinable())
        worker.join();

}

//worker function
void SCPI_server::workerLoop(){
    std::vector<int64_t> raw_data {0};
    raw_data.reserve(200);
    std::vector<double> data;
    data.reserve(40);
    double aa, bb, ab_re, ab_im, counter {0};

    tcp_socket = TcpSocket::socket_config(tcp_socket);      //here I should also modify the default buffers and stuff...
    int conn = TcpSocket::connectSocket(tcp_socket, tcp_dest_ip, tcp_dest_port);
    if(conn == -1){
        TcpSocket::closeSocket(tcp_socket);
        thread_alive = false;
        return;
    }
    std::cout << "tcp connection output: "<< conn << "\n";
    thread_alive = true;
    int ret_val {0};
    //enable the correlator
    std::cout << "starting the correlator with the following config:" <<
       "\n\tDFT size " << fpga_params.dft_size << 
       "\n\ttwiddle factor "<< fpga_params.twiddle_factor << 
       "\n\taccumulation "<< fpga_params.accumulation << 
       "\n\tintegration time " << fpga_params.integration_time << "\n";
    if(!fpga){
        std::cout << "no fpga object created!!\n";
        thread_alive = false;
        TcpSocket::closeSocket(tcp_socket);
        return;
    }

    fpga->enable_correlator();
    while(stream_running.load()){
        fpga->get_ring_buffer_data(raw_data);
        if(raw_data.size()!=0){
            switch (mode.load()) {
                case COMPLEX:
                    break;
                case RAW:{
                    auto stamp_clock = std::chrono::high_resolution_clock::now();   //if there is more than one then Im in problems...
                    std::chrono::duration<double, std::micro> stamp = stamp_clock.time_since_epoch();
                    data.push_back(stamp.count());
                    for(int i=0; i<raw_data.size()/5; ++i){
                        counter =raw_data.back();
                        raw_data.pop_back();
                        ab_im = raw_data.back();
                        raw_data.pop_back();
                        ab_re = raw_data.back();
                        raw_data.pop_back();
                        aa = raw_data.back();
                        raw_data.pop_back();
                        bb = raw_data.back();
                        raw_data.pop_back();
                        data.push_back(aa);
                        data.push_back(bb);
                        data.push_back(ab_re);
                        data.push_back(ab_im);
                    }
                    break;
                         }
                case AMP_PHASE: {
                    for(int i=0; i<raw_data.size()/5; ++i){
                        auto stamp_clock = std::chrono::high_resolution_clock::now();   //if there is more than one then Im in problems...
                        std::chrono::duration<double, std::micro> stamp = stamp_clock.time_since_epoch();
                        data.push_back(stamp.count());
                        counter =raw_data.back();
                        raw_data.pop_back();
                        ab_im = raw_data.back();
                        raw_data.pop_back();
                        ab_re = raw_data.back();
                        raw_data.pop_back();
                        aa = raw_data.back();
                        raw_data.pop_back();
                        bb = raw_data.back();
                        raw_data.pop_back();
                        data.push_back(std::sqrt(aa/bb));
                        data.push_back(std::atan2(ab_im, ab_re));
                    }
                    break;
                                }
                default:{
                    for(int i=0; i<raw_data.size()/5; ++i){
                        auto stamp_clock = std::chrono::high_resolution_clock::now();   //if there is more than one then Im in problems...
                        std::chrono::duration<double, std::micro> stamp = stamp_clock.time_since_epoch();
                        data.push_back(stamp.count());
                        counter =raw_data.back();
                        raw_data.pop_back();
                        ab_im = raw_data.back();
                        raw_data.pop_back();
                        ab_re = raw_data.back();
                        raw_data.pop_back();
                        aa = raw_data.back();
                        raw_data.pop_back();
                        bb = raw_data.back();
                        raw_data.pop_back();
                        data.push_back(std::sqrt(aa/bb));
                        data.push_back(std::atan2(ab_im, ab_re));
                    }
                    break;
                        }
            }


            if(!stream_paused.load()){
                ret_val = TcpSocket::sendVectorData(tcp_socket, data);
                data.clear();
                if(ret_val<0){
                    //error sending data.. so we try to reconnect once
                    //if we want to be more cautious we can keep trying to connect
                    TcpSocket::closeSocket(tcp_socket);
                    tcp_socket = TcpSocket::socket_config(tcp_socket);
                    conn = TcpSocket::connectSocket(tcp_socket, tcp_dest_ip, tcp_dest_port);
                        if(conn == -1){
                            thread_alive = false;
                            TcpSocket::closeSocket(tcp_socket);
                            return;
                        }
                }

            }

        }

    }
    std::cout << "out of the thread while1 \n";
    thread_alive = false;
    TcpSocket::closeSocket(tcp_socket);
}





int SCPI_server::check_message(){
    int recv_bytes = UdpSocket::recvFrom(sock,
            buffer, 
            sizeof(buffer),
            client_addr);
    return recv_bytes;
}

int SCPI_server::answer_request(std::string &out_msg){
    int bytes_out =UdpSocket::sendTo(sock, out_msg.data(), out_msg.size(), client_addr);
    return bytes_out;
}

int SCPI_server::addTimestampAnswer(std::string &out_msg){
    using namespace std::chrono;

    auto now = system_clock::now();
    auto ms =
        duration_cast<milliseconds>(
            now.time_since_epoch()) % 1000;
    auto tt = system_clock::to_time_t(now);
    std::tm tm = *gmtime(&tt);
    std::ostringstream oss;
    oss << std::put_time(
                &tm,
                "%Y-%m-%dT%H:%M:%S")
        << '.'
        << std::setw(3)
        << std::setfill('0')
        << ms.count()
        << "+0000";
    out_msg +=" "+oss.str()+"\n";
    return 0;
}



int SCPI_server::parse_recv_message(const char* recv_buff, int recv_bytes, std::string &out_msg){
    std::string_view input_data(buffer, static_cast<size_t>(recv_bytes));
    for(auto& pair: this->cmds){
        if(input_data.find(pair.first) != std::string_view::npos){
            std::cout << "match! "<< pair.first << "\n";
	    out_msg = pair.first+" ";
            int cmd_out = (this->*pair.second)(input_data, out_msg);
            return cmd_out;
        }
    }
    std::cout << "no match\n";
    out_msg.assign("undefined command!");
    SCPI_server::addTimestampAnswer(out_msg);
    return -1;
}

//
//  These are the command that actually does something
//


int SCPI_server::program_fpga(std::string_view msg, std::string& out_msg){
    if(fpga)
        fpga.reset();

    fpga.emplace(
            fpga_binfile,
            fpga_dev_mem,
            axi_reg_info,
            axi_bram_info,
            axi_snapshot_info,
            axi_ring_info
            );
    if(fpga)
        //out_msg = msg + " OK";
        out_msg += " OK";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;   
}

int SCPI_server::set_accumulation(std::string_view msg, std::string& out_msg){
    int acc = 0;
    get_int_value_from_msg(msg, acc);
    if(~stream_running.load()){
        if(fpga){
            std::cout << "setting accumulation to "<< acc <<"\n";
            if(fpga->set_accumulation(acc)){
                out_msg += "ERROR!";
                SCPI_server::addTimestampAnswer(out_msg);
                return -1;
            }
            //out_msg = msg + "OK";
            out_msg += "OK";
            SCPI_server::addTimestampAnswer(out_msg);
            fpga_params.accumulation = acc;
            fpga_params.integration_time = fpga_params.accumulation*fpga_params.dft_size/(fpga_params.adc_clock);
            return 0;

        }    
        else{
            out_msg += "ERROR";
            SCPI_server::addTimestampAnswer(out_msg);
            return -1;
        }
    }
    else{
        out_msg += " ERROR:STREAMING ON";
        SCPI_server::addTimestampAnswer(out_msg);
        return -1;
    }
}


int SCPI_server::get_accumulation(std::string_view msg, std::string& out_msg){
    //out_msg = msg+std::string(fpga_params.accumulation);
    out_msg = std::to_string(fpga->accumulation);
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}

int SCPI_server::set_dft_size(std::string_view msg, std::string& out_msg){
    int dft_size = 0;
    get_int_value_from_msg(msg, dft_size);
    if(~stream_running.load()){
        if(fpga){
            std::cout << "setting dft size to"<< dft_size <<"\n";
            fpga->set_dft_len(dft_size);
            out_msg +=  "OK";
            SCPI_server::addTimestampAnswer(out_msg);
            fpga_params.dft_size = dft_size;
            fpga_params.integration_time = fpga_params.accumulation*fpga_params.dft_size/(fpga_params.adc_clock);
            return 0;

        }    
        else{
            out_msg +=  "ERROR";
            SCPI_server::addTimestampAnswer(out_msg);
            return -1;
        }
    }
    else{
        out_msg += "ERROR:STREAMING ON";
        SCPI_server::addTimestampAnswer(out_msg);
        return -1;
    }

}
    
int SCPI_server::get_dft_size(std::string_view msg, std::string& out_msg){
    //out_msg = msg+" "+std::to_string(fpga_params.dft_size);
    out_msg += std::to_string(fpga->dft_len);
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}


int SCPI_server::set_twiddle_factor(std::string_view msg, std::string& out_msg){

    int twiddle = 0;
    get_int_value_from_msg(msg, twiddle);
    if(~stream_running.load()){
        if(fpga){
            std::cout << "setting twiddle factor to"<< twiddle<<"\n";
            fpga->upload_twiddle_factors(twiddle, 14);   //14 is the bin point...
            //out_msg = msg + "OK";
            out_msg +=  "OK";
            SCPI_server::addTimestampAnswer(out_msg);
            fpga_params.twiddle_factor = twiddle;
            return 0;

        }    
        else{
            //out_msg = msg + " ERROR";
            out_msg += "ERROR";
            SCPI_server::addTimestampAnswer(out_msg);
            return -1;
        }
    }
    else{
        //out_msg = msg + " ERROR:STREAMING ON";
        out_msg += "ERROR:STREAMING ON";
        SCPI_server::addTimestampAnswer(out_msg);
        return -1;
    }

}

int SCPI_server::get_twiddle_factor(std::string_view msg, std::string& out_msg){
    out_msg += std::to_string(fpga->twiddle_number);
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}



int SCPI_server::set_integration_time(std::string_view msg, std::string& out_msg){
    return 0;
}

int SCPI_server::get_integration_time(std::string_view msg, std::string& out_msg){
    //out_msg = msg+" "+std::to_string(fpga_params.integration_time);
    out_msg += std::to_string(fpga_params.integration_time);
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}




int SCPI_server::get_snapshot(std::string_view msg, std::string& out_msg){
    return -1;
}
//int enable_correlator(std::string_view msg, std::string& out_msg);
//

int SCPI_server::output_mode_config(std::string_view msg, std::string& out_msg){
    return -1;
}



int SCPI_server::help(std::string_view input_data, std::string &out_msg){
    out_msg += "This is a help message";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}



int SCPI_server::start_data_streaming(std::string_view msg, std::string& out_msg){
    if(fpga){
        if(!stream_running.load()){
            stream_paused = false;
            stream_running = true;
            std::cout << "initializing stream" << "\n";
            worker = std::thread( &SCPI_server::workerLoop, this);
            out_msg += "OK";
            SCPI_server::addTimestampAnswer(out_msg);
            return 0;
        }
        else{
            out_msg += "STREAM ALREADY RUNNING\n";
            SCPI_server::addTimestampAnswer(out_msg);
            return -1;
        }
    }
    else{
        out_msg += "ERROR: You need to program the fpga";
        SCPI_server::addTimestampAnswer(out_msg);
        return -1;
    }
}

int SCPI_server::pause_data_streaming(std::string_view msg, std::string& out_msg){
    if(stream_running.load()){
        if(stream_paused.load()){
            out_msg += "STREAM ALREADY PAUSED\n";
            SCPI_server::addTimestampAnswer(out_msg);
            return 0;
        }
        else{
            out_msg += "OK\n";
            SCPI_server::addTimestampAnswer(out_msg);
            stream_paused = true;
            return 0;
        }
    }
    else{
        out_msg += "STREAM IS NOT INITIATED\n";
        SCPI_server::addTimestampAnswer(out_msg);
        return -1;
    }
}

int SCPI_server::resume_data_streaming(std::string_view msg, std::string& out_msg){
    if(stream_running.load()){
        std::cout << "!strem_paused: " << !stream_paused.load() << "\n";
        if(stream_paused.load()){
            out_msg += "OK";
            SCPI_server::addTimestampAnswer(out_msg);
            stream_paused = false;
            return 0;
        }
        else{
            out_msg += "STREAM ALREADY RESUMED\n";
            SCPI_server::addTimestampAnswer(out_msg);
            return 0;
        }
    }
    else{
        out_msg += "STREAM IS NOT INITIATED\n";
        SCPI_server::addTimestampAnswer(out_msg);
        return -1;
    }
}

int SCPI_server::stop_data_streaming(std::string_view msg, std::string& out_msg){
    if(stream_running.load()){
        out_msg = "OK";
        SCPI_server::addTimestampAnswer(out_msg);
        stream_running = false;
        if(worker.joinable())
            worker.join();
        return 0;
    }
    else{
        out_msg = "STREAM IS NOT INITIATED\n";
        SCPI_server::addTimestampAnswer(out_msg);
        return -1;
    }
}


int SCPI_server::setDestStreamIP(std::string_view msg, std::string& out_msg){
    return 0;
}


int SCPI_server::setDestStreamPort(std::string_view msg, std::string& out_msg){
    return 0;
}


