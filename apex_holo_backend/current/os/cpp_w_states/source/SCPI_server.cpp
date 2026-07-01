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
        fpga_parameters default_params,
        int timeout, int sendsize, int recvsize, int reuse_addr){
    
    sock = UdpSocket::socket_config(-1, sendsize, recvsize, timeout, reuse_addr);
    std::cout << "opening UDP socket..";
    if(UdpSocket::bindSocket(sock, host, port))
        std::cout << "Failed to create the socket!\n";
    std::cout << "done\n";
    fpga_binfile = bin_file;
    fpga_dev_mem = dev_mem;
    
    tcp_server_ip = tcp_ip;
    tcp_server_port = tcp_port;

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
    std::this_thread::sleep_for(std::chrono::milliseconds(2));
    
    fpga->set_dft_len(default_params.dft_size);
    fpga->set_accumulation(default_params.accumulation);
    fpga->upload_twiddle_factors(default_params.twiddle_factor, 14);   //14 is the bin point...


    fpga_params = default_params;
    
    state.store(INITIALIZE);
    std::cout << "scpi constructor done\n";
}

SCPI_server::~SCPI_server(){
    UdpSocket::closeSocket(this->sock);
    if(fpga)
        fpga.reset();
    state.store(FAULTED);
    if(worker.joinable())
        worker.join();

}


//helper functions for the worker
int SCPI_server::fitsWritterFormatter(std::string& out_msg, double amp, double phase,
    std::chrono::system_clock::time_point stamp){
    //The format of the fitswritter message is:
    //encoding      char[4]: IEEE
    //data format   char[4]: F+3blank
    //packetlen     int:
    //backend id    char[8]: HOLOBE
    //timestamp     char[28]: YYYY-mm-ddTHH:MM:SS.ssss[TAI‖GPS‖UTC]+1 blank
    //integTime     int: In us
    //phasenum      int: 1 for us
    //numBeSections int: 1
    //blocking      int: 10 (above 1 assumes integration time steps)
    //***upto here we have 64 bytes
    //data: BeSec<int>+numChannel<int>2, amp<float>, phase<float>

    //data should be 2 size (amp and phase)
    out_msg = "";
    out_msg += fitsWritterMsgParams.encoding;
    out_msg += fitsWritterMsgParams.beFormat;

    out_msg.append(reinterpret_cast<char*>(&fitsWritterMsgParams.pkt_len),
            sizeof(fitsWritterMsgParams.pkt_len));

    out_msg += fitsWritterMsgParams.beName;
    SCPI_server::fitsWritterTimestamp(out_msg, stamp, fitsWritterMsgParams.timeSystem);

    out_msg.append(reinterpret_cast<char*>(&fitsWritterMsgParams.integTime_us),
            sizeof(fitsWritterMsgParams.integTime_us));

    out_msg.append(reinterpret_cast<char*>(&fitsWritterMsgParams.phaseNum),
            sizeof(fitsWritterMsgParams.phaseNum));

    out_msg.append(reinterpret_cast<char*>(&fitsWritterMsgParams.numBeSec),
            sizeof(fitsWritterMsgParams.numBeSec));

    out_msg.append(reinterpret_cast<char*>(&fitsWritterMsgParams.blockFactor),
            sizeof(fitsWritterMsgParams.blockFactor));

    //Here we start with the data part
    out_msg.append(reinterpret_cast<char*>(&fitsWritterMsgParams.numBeSec),
           sizeof(fitsWritterMsgParams.numBeSec));  //Be section (in priniple we should do like a for loop
                                                    //
    out_msg.append(reinterpret_cast<char*>(&fitsWritterMsgParams.numChannels),
            sizeof(fitsWritterMsgParams.numChannels));

    float amp_f =  static_cast<float>(amp);
    float phase_f = static_cast<float>(phase);

    out_msg.append(reinterpret_cast<char*>(&amp_f),
        sizeof(amp_f));

    out_msg.append(reinterpret_cast<char*>(&phase_f),
        sizeof(phase_f));
    return 0;
}

int SCPI_server::fitsWritterTimestamp(std::string &out_msg,
    std::chrono::system_clock::time_point stamp,
    std::string_view timeSystem
){
    using namespace std::chrono;

    //auto now = system_clock::now();

    auto ms =
        duration_cast<milliseconds>(
            stamp.time_since_epoch()) % 1000;

    auto tt = system_clock::to_time_t(stamp);

    std::tm tm = *gmtime(&tt);

    std::ostringstream oss;

    oss << std::put_time(
                &tm,
                "%Y-%m-%dT%H:%M:%S")
        << '.'
        << std::setw(4)
        << std::setfill('0')
        << ms.count();
    out_msg +=oss.str();
    out_msg += timeSystem;
    return 0;
}





//worker function
void SCPI_server::workerLoop(){
    int local_state = state.load();
    if((local_state ==FAULTED) | (local_state == SHUTDOWN))
        return;
    
    std::vector<int64_t> raw_data {0};
    raw_data.reserve(200);
    raw_data.pop_back();
    //std::vector<double> data;
    //data.reserve(40);
    std::string tcp_msg;
    tcp_msg.reserve(80);
    double aa, bb, ab_re, ab_im, counter {0};
    double amp, phase {0};

    tcp_socket = TcpSocket::socket_config(tcp_socket);      //here I should also modify the default buffers and stuff...
    std::cout << "binding socket to("<<tcp_server_ip <<","<< tcp_server_port << ")...";
    if(TcpSocket::bindListenSocket(tcp_socket, tcp_server_ip, tcp_server_port)<0){
        state.store(FAULTED);
        TcpSocket::closeSocket(tcp_socket);
        return;
    }
    std::cout << "done\n";

    sockaddr tcp_client_addr;
    int tcp_client_socket = -1;
    
    std::cout << "waiting for a connection..";
    while(1){
        tcp_client_socket = TcpSocket::acceptConnection(tcp_socket, tcp_client_addr);
        if(tcp_client_socket != -1)
            break;
        if(state.load() == FAULTED){
            TcpSocket::closeSocket(tcp_socket);
            return;
        }
    }
    std::cout << "waiting for the enable signal...";
    while(1){
        std::this_thread::sleep_for(std::chrono::milliseconds(2));
        local_state = state.load();
        if(local_state==ENABLED)
            break;
        else if((local_state == FAULTED) | (local_state == SHUTDOWN))
            break;
    }

    int ret_val {0};
    //enable the correlator
    std::cout << "starting the correlator with the following config:" <<
       "\n\tDFT size " << fpga_params.dft_size << 
       "\n\ttwiddle factor "<< fpga_params.twiddle_factor << 
       "\n\taccumulation "<< fpga_params.accumulation << 
       "\n\tintegration time " << fpga_params.integration_time << "\n";
    if(!fpga){
        std::cout << "no fpga object created!!\n";
        TcpSocket::closeSocket(tcp_socket);
        TcpSocket::closeSocket(tcp_client_socket);
        return;
    }
    //debug
    fpga->enable_correlator();
    while(1){
        local_state = state.load();
        if((local_state == FAULTED) | (local_state == SHUTDOWN))
            break;
        
        fpga->get_ring_buffer_data(raw_data);
        if(raw_data.size()>=5){
            //this is the timestamp from the os
            //auto stamp_clock = std::chrono::system_clock::now();
            //this is the timestamp from the fpga+ a first aligment
            counter =raw_data.back();
            auto stamp_clock = fpga->counter2timestamp(counter);
            //TODO maybe here I can use the FPGA clock!
            raw_data.pop_back();
            ab_im = raw_data.back();
            raw_data.pop_back();
            ab_re = raw_data.back();
            raw_data.pop_back();
            aa = raw_data.back();
            raw_data.pop_back();
            bb = raw_data.back();
            raw_data.pop_back();
            amp = std::sqrt(aa/bb);
            phase = std::atan2(ab_im, ab_re);
            if(state.load() == ENABLED){
                if(!(SCPI_server::fitsWritterFormatter(tcp_msg, amp, phase, stamp_clock))){
                    ret_val = TcpSocket::sendStringData(tcp_client_socket, tcp_msg);
                    if(ret_val<0){
                        std::cout << "Error in TCP transmission\n";
                        state.store(FAULTED);
                        continue;
                        }
                    }
                }
            }
        }
    std::cout << "out of the thread while1 \n";
    TcpSocket::closeSocket(tcp_client_socket);
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
        //out_msg = msg + "OK";
        out_msg += "OK";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;   
}

int SCPI_server::set_accumulation(std::string_view msg, std::string& out_msg){
    int acc = 0;
    get_int_value_from_msg(msg, acc);
    if(state.load()==INITIALIZE){
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
            fitsWritterMsgParams.integTime_us = fpga_params.integration_time*1000000;
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
    out_msg += std::to_string(fpga_params.accumulation);
    //out_msg = std::to_string(fpga->accumulation);
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}

int SCPI_server::set_dft_size(std::string_view msg, std::string& out_msg){
    int dft_size = 0;
    get_int_value_from_msg(msg, dft_size);
    if(state.load()==INITIALIZE){
        if(fpga){
            std::cout << "setting dft size to"<< dft_size <<"\n";
            fpga->set_dft_len(dft_size);
            out_msg +=  "OK";
            SCPI_server::addTimestampAnswer(out_msg);
            fpga_params.dft_size = dft_size;
            fpga_params.integration_time = fpga_params.accumulation*fpga_params.dft_size/(fpga_params.adc_clock);
            fitsWritterMsgParams.integTime_us = fpga_params.integration_time*1000000;
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
    out_msg += std::to_string(fpga_params.dft_size);
    //out_msg += std::to_string(fpga->dft_len);
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}


int SCPI_server::set_twiddle_factor(std::string_view msg, std::string& out_msg){

    int twiddle = 0;
    get_int_value_from_msg(msg, twiddle);
    if(state.load()==INITIALIZE){
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
        //out_msg = msg + "ERROR:STREAMING ON";
        out_msg += "ERROR:STREAMING ON";
        SCPI_server::addTimestampAnswer(out_msg);
        return -1;
    }

}

int SCPI_server::get_twiddle_factor(std::string_view msg, std::string& out_msg){
    //out_msg += std::to_string(fpga->twiddle_number);
    out_msg += std::to_string(fpga_params.twiddle_factor);
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}



int SCPI_server::set_integration_time(std::string_view msg, std::string& out_msg){
    //TODO!!
    //this is in ms. We assume that he wants to keep the dft_size as it is
    float value = -999.f;
    if(get_value_from_msg(msg, value)){
        out_msg += "ERROR";
        SCPI_server::addTimestampAnswer(out_msg);
        return -1;
    }
    std::cout << "setting integration time to " << value << "\n";
    int acc = static_cast<int>(value*1e-3/fpga_params.dft_size*fpga_params.adc_clock);
    if(fpga->set_accumulation(acc)){
        out_msg += "ERROR";
        SCPI_server::addTimestampAnswer(out_msg);
        return -1;
    }
    fpga_params.accumulation = acc;
    fpga_params.integration_time = fpga_params.accumulation*fpga_params.dft_size/(fpga_params.adc_clock);
    out_msg += "OK";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}

int SCPI_server::get_integration_time(std::string_view msg, std::string& out_msg){
    //out_msg = msg+" "+std::to_string(fpga_params.integration_time);
    out_msg += std::to_string(fpga_params.integration_time*1000.0f);
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



int SCPI_server::pause_data_streaming(std::string_view msg, std::string& out_msg){
    int local_state = state.load();
    if((local_state == ENABLED) | (local_state == DISABLED)){
        state.store(DISABLED);
        out_msg += "OK";
        SCPI_server::addTimestampAnswer(out_msg);
        return 0;
    }
    else{
        out_msg += "ERROR";
        SCPI_server::addTimestampAnswer(out_msg);
        return 0;
    }
}

int SCPI_server::resume_data_streaming(std::string_view msg, std::string& out_msg){
    int local_state = state.load();
    if((local_state == DISABLED) | (local_state == ENABLED)){
        state.store(ENABLED);
        out_msg += "OK";
        SCPI_server::addTimestampAnswer(out_msg);
        return 0;
    }
    else{
        out_msg += "ERROR";
        SCPI_server::addTimestampAnswer(out_msg);
        return 0;
    }
}


int SCPI_server::stop_data_streaming(std::string_view msg, std::string& out_msg){
    state.store(FAULTED);
    if(worker.joinable())
        worker.join();
    out_msg = "OK";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}



int SCPI_server::setDestStreamIP(std::string_view input_data, std::string& out_msg){
    size_t space = input_data.find(" ");
    if(space!= std::string_view::npos){
        std::string_view s_arg = input_data.substr(space+1);
        //now I should review that this follows the standard ip format
        size_t end_str = s_arg.find("\n");
        if(end_str!= std::string::npos){
            s_arg = s_arg.substr(0, end_str);
        }
        //std::cout << "test: " << std::to_string(end_str) <<"\n";
        //std::cout << "test2: " << s_arg.substr(0, end_str) << "\n";
        tcp_server_ip = s_arg;    //I need to check if it has \n at the end!
        std::cout << "new TPC ip " << tcp_server_ip <<"\n";
        out_msg += "OK";
        SCPI_server::addTimestampAnswer(out_msg);
        return 0;
    }
    else{
        out_msg += "ERROR";
        SCPI_server::addTimestampAnswer(out_msg);
        return -1;
    }
}

int SCPI_server::getDestStreamIP(std::string_view msg, std::string& out_msg){
    out_msg += tcp_server_ip;
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}


int SCPI_server::setDestStreamPort(std::string_view input_data, std::string& out_msg){
    size_t space = input_data.find(" ");
    if(space!= std::string_view::npos){
        std::string_view s_arg = input_data.substr(space+1);
        float arg;
        auto result = std::from_chars(s_arg.data(), s_arg.data()+s_arg.size(), arg);
        if(result.ec != std::errc{}){
            out_msg += "ERROR";
            SCPI_server::addTimestampAnswer(out_msg);
            return 1;
        }
        tcp_server_port= arg;
        out_msg += "Ok";
        SCPI_server::addTimestampAnswer(out_msg);
    }
    return 0;
}

int SCPI_server::getDestStreamPort(std::string_view msg, std::string& out_msg){
    out_msg += std::to_string(tcp_server_port);
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}


int SCPI_server::getStatus(std::string_view msg, std::string& out_msg){
    int local_state = state.load();
    if(local_state == INITIALIZE)
        out_msg += "INITIALIZE";
    else if(local_state == ENABLED)
        out_msg += "ENABLED";
    else if(local_state == DISABLED)
        out_msg += "DISABLED";
    else if(local_state == FAULTED)
        out_msg += "FAULTED";
    else if(local_state == SHUTDOWN)
        out_msg += "SHUTDOWN";
    else
        out_msg += "UNKNOWN";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}



int SCPI_server::on(std::string_view msg, std::string& out_msg){
    state.store(FAULTED);
    if(worker.joinable())
        worker.join();
    state.store(INITIALIZE);
    out_msg += "Ok";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}

int SCPI_server::off(std::string_view msg, std::string& out_msg){
    std::cout << "killing the streaming thread (if alive)...";
    int local_state = state.load();
    if((local_state == FAULTED) | (local_state == SHUTDOWN)){
        out_msg += "OK";
        SCPI_server::addTimestampAnswer(out_msg);
        return 0;
    }
    else{
        state.store(SHUTDOWN);
        if(worker.joinable())
            worker.join();
        out_msg += "OK";
        SCPI_server::addTimestampAnswer(out_msg);
        return 0;
    }
}


int SCPI_server::configure(std::string_view msg, std::string& out_msg){
     //Check if we are running the streaming thread, if so kill it
    std::cout << "killing the streaming thread (if alive)...";
    //int local_state = state.load();
    //check this!! if the fitswritter is already connected to the TCP port this will kick him out!
    //if((local_state == ENABLED) | (local_state == DISABLED) | (local_state) == FAULTED){
    state.store(FAULTED);
    if(worker.joinable())
        worker.join();
    std::cout << "done\n";
    //}
    std::cout << "done\n";
    //check if the fpga is programmed.. if not program it
    std::cout << "programming FPGA...";
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
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
    std::cout << "done\n";
    std::cout << "setting dft size..";
    if(fpga->set_dft_len(fpga_params.dft_size)){
        out_msg += "ERROR";
        SCPI_server::addTimestampAnswer(out_msg);
        return -1;
    }
    std::cout << "done\n";
    std::cout << "setting accumulation..";
    if(fpga->set_accumulation(fpga_params.accumulation)){
        out_msg += "ERROR";
        SCPI_server::addTimestampAnswer(out_msg);
        return -1;
    }
    std::cout << "done\n";
    std::cout << "uploading twiddle factor..";
    if(fpga->upload_twiddle_factors(fpga_params.twiddle_factor, 14)){
        out_msg += "ERROR";
        SCPI_server::addTimestampAnswer(out_msg);
        return -1;
    }
    state.store(INITIALIZE);
    std::cout << "starting thread..";
    worker = std::thread( &SCPI_server::workerLoop, this);
    std::cout << "done\n";
    out_msg += "OK";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}

int SCPI_server::start(std::string_view msg, std::string& out_msg){
    if(!fpga){
        std::cout << "FPGA not programmed!\n";
        out_msg += "ERROR";
        SCPI_server::addTimestampAnswer(out_msg);
        return -1;
    }
    int local_state = state.load();
    if((local_state !=FAULTED) & (local_state!= SHUTDOWN)){
        state.store(ENABLED);
        out_msg += "OK";
    }
    else{
        out_msg += "ERROR";
    }
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}


int SCPI_server::start_data_streaming(std::string_view msg, std::string& out_msg){
    return SCPI_server::start(msg, out_msg);
}


int SCPI_server::stop(std::string_view msg, std::string& out_msg){
    int local_state = state.load();
    if(local_state == ENABLED){
        state.store(DISABLED);
        out_msg += "OK";
    }
    else
        out_msg += "ERROR";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}


int SCPI_server::abort(std::string_view msg, std::string& out_msg){
    std::cout << "killing the streaming thread (if alive)...";
    state.store(FAULTED);
    if(worker.joinable())
        worker.join();
    out_msg += "OK";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}

int SCPI_server::reset(std::string_view msg, std::string& out_msg){
    state.store(FAULTED);
    if(worker.joinable())
        worker.join();
    return SCPI_server::configure(msg, out_msg);
}


int SCPI_server::get_state(std::string_view msg, std::string& out_msg){
    //The answers can be INITIALIZE, SHUTDOWN, DISABLED, ENABLED, FAULTED
    switch(state){
        case INITIALIZE:{
            out_msg+= "INITIALIZE";
            break;
            }
        case DISABLED: {
            out_msg += "DISABLED";
            break;
            }
        case ENABLED: {
            out_msg += "ENABLED";
            break;
            }
        case FAULTED: {
            out_msg += "FAULTED";
            break;
            }
        case SHUTDOWN:{
            out_msg += "SHUTDOWN";
            break;
            }
        default:{
            out_msg += "FAULTED";
            break;
            }
    }
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}



int SCPI_server::getUsedChannels(std::string_view msg, std::string& out_msg){
    out_msg += "1 1";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}


int SCPI_server::setUsedChannels(std::string_view msg, std::string& out_msg){
    //we only have one channel.. so dont 
    out_msg += "OK";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}
int SCPI_server::getNumPhases(std::string_view msg, std::string& out_msg){
    out_msg += "1";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}

int SCPI_server::setNumPhases(std::string_view msg, std::string& out_msg){
    out_msg += "OK";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;    
}

int SCPI_server::getMode(std::string_view msg, std::string& out_msg){
    out_msg += "INTERNAL";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}


int SCPI_server::setMode(std::string_view msg, std::string& out_msg){
    out_msg += "OK";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}

int SCPI_server::getGain(std::string_view msg, std::string& out_msg){
    out_msg += "-999";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}

int SCPI_server::setGain(std::string_view msg, std::string& out_msg){
    out_msg += "OK";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}

int SCPI_server::getVersion(std::string_view msg, std::string& out_msg){
    out_msg += "0.1";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}

int SCPI_server::get_sync_time(std::string_view msg, std::string& out_msg){
    out_msg += "2000";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}

int SCPI_server::set_sync_time(std::string_view msg, std::string& out_msg){
    out_msg += "OK";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}

int SCPI_server::get_blank_time(std::string_view msg, std::string& out_msg){
    out_msg += "10";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}

int SCPI_server::set_blank_time(std::string_view msg, std::string& out_msg){
    out_msg += "OK";
    SCPI_server::addTimestampAnswer(out_msg);
    return 0;
}



