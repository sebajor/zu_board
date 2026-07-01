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
#include <charconv>

enum output_mode {
    COMPLEX,
    RAW,
    AMP_PHASE
};

enum sys_status {
  INITIALIZE,
  SHUTDOWN,
  DISABLED,
  ENABLED,
  FAULTED
};

struct fpga_parameters {
    int accumulation =-999;
    int dft_size = -999;
    float integration_time = -999;
    int twiddle_factor =-999;
    float adc_clock = 100*1e6;
};


struct fitsWritterParams {
    std::string_view encoding = "EEEI";
    std::string_view beFormat = "F   ";
    int32_t pkt_len = 80;
    std::string_view beName = "HOLOBE  ";
    std::string_view timeSystem ="TAI "; 
    int32_t integTime_us = 2000;
    int32_t phaseNum = 1;
    int32_t numBeSec = 1;
    int32_t blockFactor = 1;//if larger than 1 assumes equidistant steps
    int32_t numChannels = 2;
};


class SCPI_server {
    private:
        std::optional<apexHoloBackend> fpga;
        int sock {-1};
        int tcp_socket{-1};
        std::string_view tcp_server_ip {"0.0.0.0"}; //check!!!
        int tcp_server_port {12334};
        sockaddr_in client_addr;
        
        axi_lite_reg axi_reg_info {};
        axi_lite_reg axi_bram_info {};
        axi_lite_reg axi_snapshot_info {};
        axi_lite_reg axi_ring_info {};
        std::string fpga_binfile;
        std::string fpga_dev_mem;
        std::thread worker;
        
        fitsWritterParams fitsWritterMsgParams;
        std::atomic<sys_status> state = INITIALIZE;


    public:
        SCPI_server(std::string_view ip, int port, 
                std::string_view tcp_ip, int tcp_port,
                const std::string &binfile,const std::string &dev_mem,
                const axi_lite_reg &axil_reg, const axi_lite_reg &axil_bram,
                const axi_lite_reg &snapshot_bram, const axi_lite_reg &axi_ring, 
                fpga_parameters default_params,
                int timeout=-1, int sendsize=128, int recvsize=128, int reuse_addr=1);
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
        int getDestStreamIP(std::string_view msg, std::string& out_msg);
        int setDestStreamPort(std::string_view msg, std::string& out_msg);
        int getDestStreamPort(std::string_view msg, std::string& out_msg);



        int fitsWritterFormatter(std::string& out_msg, double amp, double phase,
            std::chrono::system_clock::time_point stamp);

        int fitsWritterTimestamp(std::string &out_msg,
            std::chrono::system_clock::time_point stamp,
            std::string_view timeSystem
        );



	    int getStatus(std::string_view msg, std::string& out_msg);

        //fitswritter functions
        int on(std::string_view msg, std::string& out_msg);
        int off(std::string_view msg, std::string& out_msg);
        int configure(std::string_view msg, std::string& out_msg);
        int start(std::string_view msg, std::string& out_msg);
        int stop(std::string_view msg, std::string& out_msg);
        int abort(std::string_view msg, std::string& out_msg);
        int reset(std::string_view msg, std::string& out_msg);
        int get_state(std::string_view msg, std::string& out_msg);
        int getUsedChannels(std::string_view msg, std::string& out_msg);
        int setUsedChannels(std::string_view msg, std::string& out_msg);
        int get_sync_time(std::string_view msg, std::string& out_msg);
        int set_sync_time(std::string_view msg, std::string& out_msg);
        int get_blank_time(std::string_view msg, std::string& out_msg);
        int set_blank_time(std::string_view msg, std::string& out_msg);
        int getNumPhases(std::string_view msg, std::string& out_msg);
        int setNumPhases(std::string_view msg, std::string& out_msg);
        int getMode(std::string_view msg, std::string& out_msg);
        int setMode(std::string_view msg, std::string& out_msg);
        int getGain(std::string_view msg, std::string& out_msg);
        int setGain(std::string_view msg, std::string& out_msg);
        int getVersion(std::string_view msg, std::string& out_msg);

        //commands and the corresponden methods
        using cmdHandler = int(SCPI_server::*)(std::string_view, std::string&);
        std::vector<std::pair<std::string, cmdHandler>> cmds {
            {"APEX:HOLOBE:PROGRAM_FPGA", &SCPI_server::program_fpga},
            {"APEX:HOLOBE:SET_ACCUMULATION", &SCPI_server::set_accumulation},
            {"APEX:HOLOBE:GET_ACCUMULATION", &SCPI_server::get_accumulation},
            {"APEX:HOLOBE:SET_DFT_SIZE", &SCPI_server::set_dft_size},
            {"APEX:HOLOBE:GET_DFT_SIZE", &SCPI_server::get_dft_size},
            {"APEX:HOLOBE:GET_SNAPSHOT", &SCPI_server::get_snapshot},
            {"APEX:HOLOBE:SET_TWIDDLE_FACTOR", &SCPI_server::set_twiddle_factor},
            {"APEX:HOLOBE:GET_TWIDDLE_FACTOR", &SCPI_server::get_twiddle_factor},
            {"APEX:HOLOBE:SET_INTEGRATION_TIME", &SCPI_server::set_integration_time},
            {"APEX:HOLOBE:GET_INTEGRATION_TIME", &SCPI_server::get_integration_time},
            {"APEX:HOLOBE:HELP", &SCPI_server::help},
            {"APEX:HOLOBE:START_DATA_STREAM", &SCPI_server::start_data_streaming},
            {"APEX:HOLOBE:PAUSE_DATA_STREAM", &SCPI_server::pause_data_streaming},
            {"APEX:HOLOBE:RESUME_DATA_STREAM", &SCPI_server::resume_data_streaming},
            {"APEX:HOLOBE:STOP_DATA_STREAM", &SCPI_server::stop_data_streaming},
            {"APEX:HOLOBE:MODE", &SCPI_server::output_mode_config},
            {"APEX:HOLOBE:SET_DEST_IP", &SCPI_server::setDestStreamIP},
            {"APEX:HOLOBE:GET_DEST_IP", &SCPI_server::getDestStreamIP},
            {"APEX:HOLOBE:SET_DEST_PORT", &SCPI_server::setDestStreamPort},
            {"APEX:HOLOBE:GET_DEST_PORT", &SCPI_server::getDestStreamPort},
            {"APEX:HOLOBE:GET_STATUS", &SCPI_server::getStatus},
            
            //TODO!!!!
            {"APEX:HOLOBE:on", &SCPI_server::on},
            {"APEX:HOLOBE:off", &SCPI_server::off},
            {"APEX:HOLOBE:configure", &SCPI_server::configure},
            {"APEX:HOLOBE:start", &SCPI_server::start},
            {"APEX:HOLOBE:stop", &SCPI_server::stop},
            {"APEX:HOLOBE:abort", &SCPI_server::abort},
            {"APEX:HOLOBE:reset", &SCPI_server::reset},
            {"APEX:HOLOBE:state?", &SCPI_server::get_state},

            {"APEX:HOLOBE:integrationTime?", &SCPI_server::get_integration_time},
            {"APEX:HOLOBE:cmdIntegrationTime?", &SCPI_server::get_integration_time},
            {"APEX:HOLOBE:cmdIntegrationTime", &SCPI_server::set_integration_time},
            {"APEX:HOLOBE:usedChannels?", &SCPI_server::getUsedChannels},
            {"APEX:HOLOBE:cmdUsedChannels?", &SCPI_server::getUsedChannels},
            {"APEX:HOLOBE:cmdUsedChannels", &SCPI_server::setUsedChannels},

            {"APEX:HOLOBE:syncTime?", &SCPI_server::get_sync_time},
            {"APEX:HOLOBE:cmdSyncTime?", &SCPI_server::get_sync_time},
            {"APEX:HOLOBE:cmdSyncTime", &SCPI_server::set_sync_time},
            {"APEX:HOLOBE:blankTime?", &SCPI_server::get_blank_time},
            {"APEX:HOLOBE:cmdBlankTime?", &SCPI_server::get_blank_time},
            {"APEX:HOLOBE:cmdBlankTime", &SCPI_server::set_blank_time},


            {"APEX:HOLOBE:numPhases?", &SCPI_server::getNumPhases},
            {"APEX:HOLOBE:cmdNumPhases?", &SCPI_server::getNumPhases},
            {"APEX:HOLOBE:cmdNumPhases", &SCPI_server::setNumPhases},
            {"APEX:HOLOBE:mode?", &SCPI_server::getMode},
            {"APEX:HOLOBE:cmdMode?", &SCPI_server::getMode},
            {"APEX:HOLOBE:cmdMode", &SCPI_server::setMode},
            {"APEX:HOLOBE:gain?", &SCPI_server::getGain},
            {"APEX:HOLOBE:cmdGain?", &SCPI_server::getGain},
            {"APEX:HOLOBE:cmdGain", &SCPI_server::setGain},
            {"APEX:HOLOBE:version?", &SCPI_server::getVersion},
        };
};


int get_int_value_from_msg(std::string &msg);

template <typename T>
int get_value_from_msg(std::string_view &msg, T& value){
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




