#include <vector>
#include <utility>
#include <string>
#include <mutex>
#include "../includes/SCPI_server.h"
#include <cstring>

SCPI_server::SCPI_server(apexHoloBackend &apex_fpga, std::mutex &shared_mutex, 
        std::string_view udp_ip, int udp_port, 
        std::string &tcp_ip, int tcp_port, 
        int timeout=1,  int send_size=1024, int recv_size=1024, int reuse_addr=1)
    :fpga(apex_fpga),
    mut(shared_mutex),
    tcp_ip(tcp_ip),
    tcp_port(tcp_port)
{

    //start the udp server
    //
    this->udp_sock_fd = UdpSocket::socket_config(-1, send_size, recv_size, timeout, reuse_addr);
    if(UdpSocket::bindSocket(this->udp_sock_fd, udp_ip, udp_port))
        std::cout << "Failed to create the UDP socket!\n";
}

SCPI_server::~SCPI_server(){
    UdpSocket::closeSocket(this->udp_sock_fd);
    if(this->tcp_sock_fd!=-1)
        TcpSocket::closeSocket(this->tcp_sock_fd);
}


int SCPI_server::parse_recv_msg(std::string &input_data, std::string &out_msg){
    /*
     *  See if it found a match with the SCPI commands and execute the function associated
     */
    for(auto& pair: this->cmds){
        if(input_data.find(pair.first) != std::string::npos){
            std::cout << "match! "<< pair.first << "\n";
            int cmd_out = (this->*pair.second)(input_data, out_msg); 
            
            return 1;
        }
    }
    std::cout << "no match\n";
    out_msg.assign("undefined command!\n");
    return -1;
}

int SCPI_server::check_messages(){
    int recv = UdpSocket::recvFrom(this->udp_sock_fd, this->recv_buffer, 
            this->recv_len, this->udp_client_addr);
    if(recv>0){
        this->recv_msg = recv_buffer.data();
        this->parse_recv_msg(this->recv_msg, this->ans);
        return 0;
    }
    return recv;
}

int SCPI_server::answer_request(){
    int out = UdpSocket::sendTo(this->udp_sock_fd, this->ans.data(), 
            (this->ans.size())*sizeof(char), this->udp_client_addr);
    return out;
}


//internal functions
int SCPI_server::zuboard_set_acc(std::string &msg, std::string &out_msg){
    //first we will try to get the argument
    size_t space = msg.find(" ");
    if(space!= std::string::npos){
        std::string s_arg = msg.substr(space+1);
        try{
            float arg = std::stof(std::string(s_arg));
            std::cout << "setting acc to "<< s_arg << "\n";
            std::lock_guard<std::mutex> lock(this->mut);
            this->fpga.set_accumulation(arg);
            out_msg.assign(std::string(msg.substr(0,space)).append(" OK\n"));
            this->integ_time = this->fpga.accumulation*this->fpga.dft_len/this->adc_clock;
            return 0;
        }
        catch(...){
            std::cout << "ERROR in set accumualtion!\n";
            std::cout << msg << "\n";
            out_msg.assign(std::string(msg.substr(0,space)).append(" ERROR!\n"));
            return 1;
        }
    }
    out_msg.assign(" ERROR!\n");
    return 1;
};



int SCPI_server::zuboard_get_acc(std::string &msg, std::string &out_msg){
    try{
        std::lock_guard<std::mutex> lock(this->mut);
        out_msg.assign(std::string(msg.substr(0, msg.size()-1))+" "+
            std::to_string(this->fpga.accumulation)+
            " \n");
        return 0;
        }
    catch(...){
            std::cout << "ERROR in getting accumualtion!\n";
            std::cout << msg << "\n";
            out_msg.assign(std::string(msg.substr(0, msg.size()-1)).append(" ERROR!\n"));
            return 1;
    }
};


int SCPI_server::zuboard_set_dft_size(std::string &msg, std::string &out_msg){
    //try to get the arg
    size_t space = msg.find(" ");
    if(space!= std::string::npos){
        std::string s_arg = msg.substr(space+1);
        try{
            float arg = std::stof(s_arg);
            std::cout << "setting dft size to "<< s_arg << "\n";
            std::lock_guard<std::mutex> lock(this->mut);
            this->fpga.set_dft_len(arg);
            out_msg.assign(std::string(msg.substr(0,space)).append(" OK\n"));
            this->integ_time = this->fpga.accumulation*this->fpga.dft_len/this->adc_clock;
            return 0;
        }
        catch(...){
            std::cout << "ERROR in set dft size!\n";
            std::cout << msg << "\n";
            out_msg.assign(std::string(msg.substr(0,space)).append(" ERROR!\n"));
            return 1;
        }
    }
    out_msg.assign(" ERROR!\n");
    return 1;
};

int SCPI_server::zuboard_get_dft_size(std::string &msg, std::string &out_msg){
    try{
        std::lock_guard<std::mutex> lock(this->mut);
        out_msg.assign(std::string(msg.substr(0, msg.size()-1))+" "+
            std::to_string(this->fpga.dft_len)+
            " \n");
        return 0;
        }
    catch(...){
            std::cout << "ERROR in getting DFT size!\n";
            std::cout << msg << "\n";
            out_msg.assign(std::string(msg.substr(0, msg.size()-1)).append(" ERROR!\n"));
            return 1;
    }
};


int SCPI_server::zuboard_set_twiddle(std::string &msg, std::string &out_msg){
    //try to get the arg
    size_t space = msg.find(" ");
    if(space!= std::string::npos){
        std::string s_arg = msg.substr(space+1);
        try{
            float arg = std::stof(s_arg);
            std::cout << "setting twiddle to "<< s_arg << "\n";
            std::lock_guard<std::mutex> lock(this->mut);
            this->fpga.upload_twiddle_factors(arg, this->fpga.twiddle_point);
            out_msg.assign(std::string(msg.substr(0,space)).append(" OK\n"));
            return 0;
        }
        catch(...){
            std::cout << "ERROR in set the twiddle factor!\n";
            std::cout << msg << "\n";
            out_msg.assign(std::string(msg.substr(0,space)).append(" ERROR!\n"));
            return 1;
        }
    }
    out_msg.assign(" ERROR!\n");
    return 1;
};

int SCPI_server::zuboard_get_twiddle(std::string &msg, std::string &out_msg){
    try{
        std::lock_guard<std::mutex> lock(this->mut);
        out_msg.assign(std::string(msg.substr(0, msg.size()-1))+" "+
            std::to_string(this->fpga.twiddle_number)+
            " \n");
        return 0;
        }
    catch(...){
            std::cout << "ERROR in getting twiddle factor!\n";
            std::cout << msg << "\n";
            out_msg.assign(std::string(msg.substr(0, msg.size()-1)).append(" ERROR!\n"));
            return 1;
    }
    return 0;
};


int SCPI_server::zuboard_get_snapshot(std::string &msg, std::string &out_msg){
    try{
        std::lock_guard<std::mutex> lock(this->mut);
        this->fpga.get_snapshot(this->adc0_snapshot, this->adc1_snapshot);
        //now we convert ythe data to strings...
        //this is not ideal bcs 
        std::memcpy((this->adc0_str).data(), (this->adc0_snapshot).data(), (this->adc0_str).size());
        std::memcpy((this->adc1_str).data(), (this->adc1_snapshot).data(), (this->adc1_str).size());
        //now I have to see how to send this over the connection..
        out_msg.assign(std::string(msg)+"ADC0:"+this->adc0_str+" ADC1:"+this->adc1_str+"\n");
        return 0;
    }
    catch(...){
        std::cout << "ERROR in getting snapshot!\n";
        std::cout << msg << "\n";
        out_msg.assign(std::string(msg.substr(0, msg.size()-1)).append(" ERROR!\n"));
        return 1;
    }
};


int SCPI_server::zuboard_enable_corr(std::string &msg, std::string &out_msg){
    try{
        std::lock_guard<std::mutex> lock(this->mut);
        this->fpga.enable_correlator();
        out_msg.assign(std::string(msg.substr(0, msg.size()-1))+" OK\n");
        return 0;
    }
    catch(...){
            std::cout << "ERROR enabling correaltor factor!\n";
            std::cout << msg << "\n";
            out_msg.assign(std::string(msg.substr(0, msg.size()-1)).append(" ERROR!\n"));
            return 1;
    }
    return 0;
};

int SCPI_server::zuboard_continous_stream(std::string &msg, std::string &out_msg){
    try{
        std::lock_guard<std::mutex> lock(this->mut);
        if(this->data_flag==0){
            this->fpga.enable_correlator();
            this->data_flag = 1;
        }
        out_msg.assign(std::string(msg.substr(0, msg.size()-1))+" OK\n");
        return 0;
    }
    catch(...){
        std::cout << "Error initializing the continous data stream!\n";
        out_msg.assign(std::string(msg.substr(0, msg.size()-1)).append(" ERROR!\n"));
        return 1;
    }
};

int SCPI_server::zuboard_disable_continous_stream(std::string &msg, std::string &out_msg){
    try{
        if(this->data_flag==1)
            this->data_flag = 0;
        out_msg.assign(std::string(msg.substr(0, msg.size()-1))+" OK\n");
        return 0;
    }
    catch(...){
        std::cout << "Error ending the continous data stream!\n";
        out_msg.assign(std::string(msg.substr(0, msg.size()-1)).append(" ERROR!\n"));
        return 1;
    }
}



int SCPI_server::zuboard_set_integration_time(std::string &msg, std::string &out_msg){
    //try to get the arg
    size_t space = msg.find(" ");
    if(space!= std::string::npos){
        std::string s_arg = msg.substr(space+1);
        try{
            float arg = std::stof(s_arg);
            std::cout << "setting integration time to "<< s_arg << "\n";
            int acc = static_cast<int>(arg*this->adc_clock/this->fpga.dft_len);
            std::cout << "Using acc len: "<< acc <<"\n";
            std::lock_guard<std::mutex> lock(this->mut);
            this->fpga.set_accumulation(acc);
            out_msg.assign(std::string(msg.substr(0,space)).append(" OK\n"));
            this->integ_time = this->fpga.accumulation*this->fpga.dft_len/this->adc_clock;
            return 0;
        }
        catch(...){
            std::cout << "ERROR in set the integration time!\n";
            std::cout << msg << "\n";
            out_msg.assign(std::string(msg.substr(0,space)).append(" ERROR!\n"));
            return 1;
        }
    }
    out_msg.assign(" ERROR!\n");
    return 1;
};

int SCPI_server::zuboard_get_integration_time(std::string &msg, std::string &out_msg){
    try{
        std::lock_guard<std::mutex> lock(this->mut);
        out_msg.assign(std::string(msg.substr(0, msg.size()-1))+" "+
            std::to_string(this->integ_time)+
            " \n");
        return 0;
        }
    catch(...){
            std::cout << "ERROR in getting integration time!\n";
            std::cout << msg << "\n";
            out_msg.assign(std::string(msg.substr(0, msg.size()-1)).append(" ERROR!\n"));
            return 1;
    }
    return 1;
};

int SCPI_server::zuboard_get_reg(std::string &msg, std::string &out_msg){
    std::array<uint64_t, 4> read_data;
    try{
        if(this->data_flag){
            out_msg.assign(std::string(msg.substr(0, msg.size()-1)).append(" ERROR! CONT STREAM ON\n"));
            return 0;
        }
        std::lock_guard<std::mutex> lock(this->mut);
        this->fpga.acknowledge_data();
        this->fpga.get_register_data(read_data);
        out_msg.assign(msg);
        out_msg.append(reinterpret_cast<const char*>(read_data.data()), read_data.size()*sizeof(uint64_t));
        return 0;
    }
    catch(...){
            std::cout << "ERROR in getting integration time!\n";
            std::cout << msg << "\n";
            out_msg.assign(std::string(msg.substr(0, msg.size()-1)).append(" ERROR!\n"));
            return 1;
    }
    return 1;
};

//TODO!!!

int SCPI_server::zuboard_set_dest_ip(std::string &msg, std::string &out_msg){
    return 0;
};
int SCPI_server::zuboard_get_dest_ip(std::string &msg, std::string &out_msg){
    return 0;
};
int SCPI_server::zuboard_set_dest_port(std::string &msg, std::string &out_msg){
    return 0;
};
int SCPI_server::zuboard_get_dest_port(std::string &msg, std::string &out_msg){
    return 0;
};
int SCPI_server::zuboard_start_acquisition(std::string &msg, std::string &out_msg){
    //I should connect to the tcp server
    //here I should use: this will initialize the correlator this->fpga.enable_correlator(); 
    return 0;
};

