#include "UdpSocket.h"
#include "apexHoloBackend.h"
#include <vector>
#include <iostream>
#include <utility>
#include <string>
#include <atomic>
#include <mutex>
#include <thread>
#include <optional>

enum output_mode {
    COMPLEX,
    RAW,
    AMP_PHASE
};

struct fpga_parameters {
    int accumulation =-1;
    int dft_size = -1;
    float integration_time = -1;
    int twiddle_factor =-1;
    float adc_clock = 100*1e6;
};


class SCPI_server {
    private:
        std::optional<apexHoloBackend> fpga;
        int sock {-1};
        int tcp_socket{-1};
        std::string_view tcp_dest_ip {"10.0.33.133"};
        int tcp_dest_port {12334};
        sockaddr_in client_addr;


        axi_lite_reg axi_reg_info {};
        axi_lite_reg axi_bram_info {};
        axi_lite_reg axi_snapshot_info {};
        axi_lite_reg axi_ring_info {};
        std::string fpga_binfile;
        std::string fpga_dev_mem;
        

        std::atomic<output_mode> mode = COMPLEX;
        std::atomic<bool> stream_running {false};
        std::atomic<bool> stream_paused {false};
        std::atomic<bool> thread_alive {false};
        std::thread worker;


    public:
        SCPI_server(std::string_view ip, int port, 
                std::string_view tcp_ip, int tcp_port,
                const std::string &binfile,const std::string &dev_mem,
                const axi_lite_reg &axil_reg, const axi_lite_reg &axil_bram,
                const axi_lite_reg &snapshot_bram, const axi_lite_reg &axi_ring, 
                int timeout=-1, int sendsize=1024, int recvsize=1024, int reuse_addr=1);
        ~SCPI_server();
        
        char buffer[2048] {0};
        std::string ans {0};

        
        int parse_recv_message(const char* recv_buff, int recv_bytes, std::string& out_msg);
        int check_message();
        int answer_request(std::string &out_msg);
        int addTimestampAnswer(std::string &out_msg);

        void workerLoop();
        //
        fpga_parameters fpga_params;
        
        //scpi methods
        int program_fpga(std::string_view msg, std::string& out_msg);

        int set_accumulation(std::string_view msg, std::string& out_msg);
        int get_accumulation(std::string_view msg, std::string& out_msg);

        int set_dft_size(std::string_view msg, std::string& out_msg);
        int get_dft_size(std::string_view msg, std::string& out_msg);
        int set_twiddle_factor(std::string_view msg, std::string& out_msg);
        int get_twiddle_factor(std::string_view msg, std::string& out_msg);
        int get_snapshot(std::string_view msg, std::string& out_msg);
        int set_integration_time(std::string_view msg, std::string& out_msg);
        int get_integration_time(std::string_view msg, std::string& out_msg);
        //int enable_correlator(std::string_view msg, std::string& out_msg);
        int help(std::string_view msg, std::string& out_msg);

        int output_mode_config(std::string_view msg, std::string& out_msg);
        int start_data_streaming(std::string_view msg, std::string& out_msg);
        int pause_data_streaming(std::string_view msg, std::string& out_msg);
        int resume_data_streaming(std::string_view msg, std::string& out_msg);
        int stop_data_streaming(std::string_view msg, std::string& out_msg);


        int setDestStreamIP(std::string_view msg, std::string& out_msg);
        int setDestStreamPort(std::string_view msg, std::string& out_msg);

        //commands and the corresponden methods
        //
        using cmdHandler = int(SCPI_server::*)(std::string_view, std::string&);
        std::vector<std::pair<std::string, cmdHandler>> cmds {
            {"APEX:HOLO:CORNETOSCOPIO:PROGRAM_FPGA", &SCPI_server::program_fpga},
            {"APEX:HOLO:CORNETOSCOPIO:SET_ACCUMULATION", &SCPI_server::set_accumulation},
            {"APEX:HOLO:CORNETOSCOPIO:GET_ACCUMULATION", &SCPI_server::get_accumulation},
            {"APEX:HOLO:CORNETOSCOPIO:SET_DFT_SIZE", &SCPI_server::set_dft_size},
            {"APEX:HOLO:CORNETOSCOPIO:GET_DFT_SIZE", &SCPI_server::get_dft_size},
            {"APEX:HOLO:CORNETOSCOPIO:GET_SNAPSHOT", &SCPI_server::get_snapshot},
            {"APEX:HOLO:CORNETOSCOPIO:SET_TWIDDLE_FACTOR", &SCPI_server::set_twiddle_factor},
            {"APEX:HOLO:CORNETOSCOPIO:GET_TWIDDLE_FACTOR", &SCPI_server::get_twiddle_factor},
            {"APEX:HOLO:CORNETOSCOPIO:SET_INTEGRATION_TIME", &SCPI_server::set_integration_time},
            {"APEX:HOLO:CORNETOSCOPIO:GET_INTEGRATION_TIME", &SCPI_server::get_integration_time},
            {"APEX:HOLO:CORNETOSCOPIO:HELP", &SCPI_server::help},
            {"APEX:HOLO:CORNETOSCOPIO:START_DATA_STREAM", &SCPI_server::start_data_streaming},
            {"APEX:HOLO:CORNETOSCOPIO:PAUSE_DATA_STREAM", &SCPI_server::pause_data_streaming},
            {"APEX:HOLO:CORNETOSCOPIO:RESUME_DATA_STREAM", &SCPI_server::resume_data_streaming},
            {"APEX:HOLO:CORNETOSCOPIO:STOP_DATA_STREAM", &SCPI_server::resume_data_streaming},
            {"APEX:HOLO:CORNETOSCOPIO:MODE", &SCPI_server::output_mode_config},
        };



};


int get_int_value_from_msg(std::string &msg);




