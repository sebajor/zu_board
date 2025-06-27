#include "TcpServer.h"
#include "apexHoloBackend.h"
#include <vector>
#include <array>
#include <string>
#include <utility>
#include <mutex>
#include <atomic>
#include <thread>


class SCPI_server {
    private:
        apexHoloBackend &fpga;
        std::array<int16_t, SNAPSHOT_SAMPLES> adc0_snapshot{0};
        std::array<int16_t, SNAPSHOT_SAMPLES> adc1_snapshot{0};
        std::string adc0_str = std::string(SNAPSHOT_SAMPLES*sizeof(int16_t), '\0');;
        std::string adc1_str = std::string(SNAPSHOT_SAMPLES*sizeof(int16_t), '\0');;
        std::thread worker;
    public:
        TcpServer cmd_server;
        TcpServer data_server;
        int internal_value = -1;
        float adc_clock = 100*1e6;
        float integ_time = -1;
        //this are the flags used to handle the threads safetly
        std::mutex mut;
        std::atomic<int> data_flag = 0;
        std::atomic<int> alive = 1;
        //
        SCPI_server(std::string_view ip, int cmd_port, int data_port, apexHoloBackend &apex_fpga);
        ~SCPI_server();
        int parse_recv_msg(std::string_view input_data, std::string &out_msg);
        
        void data_thread();
        

        //methods.. always returns a int that shows if the action was successfull
        //the msg is the received one, the out_msg is the string that will be send to
        //the client and the fpga is the interface that to the FPGA
        
        int zuboard_set_acc(std::string_view msg, std::string &out_msg );
        int zuboard_get_acc(std::string_view msg, std::string &out_msg );
        int zuboard_set_dft_size(std::string_view msg, std::string &out_msg );
        int zuboard_get_dft_size(std::string_view msg, std::string &out_msg );
        int zuboard_set_twiddle(std::string_view msg, std::string &out_msg );
        int zuboard_get_twiddle(std::string_view msg, std::string &out_msg );
        int zuboard_get_snapshot(std::string_view msg, std::string &out_msg );
        int zuboard_enable_corr(std::string_view msg, std::string &out_msg );
        int zuboard_continous_stream(std::string_view msg, std::string &out_msg);
        int zuboard_disable_continous_stream(std::string_view msg, std::string &out_msg);
        int zuboard_set_integration_time(std::string_view msg, std::string &out_msg);
        int zuboard_get_integration_time(std::string_view msg, std::string &out_msg);

        int zuboard_get_reg(std::string_view msg, std::string &out_msg );


        //commands and the corresponding methods
        std::vector<std::pair<std::string_view, int(SCPI_server::*)(std::string_view, std::string&)>> cmds {
            {"HOLO:ZUBOARD:SET_ACC", &SCPI_server::zuboard_set_acc},
            {"HOLO:ZUBOARD:GET_ACC", &SCPI_server::zuboard_get_acc},
            {"HOLO:ZUBOARD:SET_DFT_SIZE", &SCPI_server::zuboard_set_dft_size},
            {"HOLO:ZUBOARD:GET_DFT_SIZE", &SCPI_server::zuboard_get_dft_size},
            {"HOLO:ZUBOARD:SET_TWIDDLE", &SCPI_server::zuboard_set_twiddle},
            {"HOLO:ZUBOARD:GET_TWIDDLE", &SCPI_server::zuboard_get_twiddle},
            {"HOLO:ZUBOARD:GET_SNAPSHOT", &SCPI_server::zuboard_get_snapshot},
            {"HOLO:ZUBOARD:GET_REG", &SCPI_server::zuboard_get_reg},
            {"HOLO:ZUBOARD:ENABLE_CORR", &SCPI_server::zuboard_enable_corr},
            {"HOLO:ZUBOARD:CONTINOUS_STREAM", &SCPI_server::zuboard_continous_stream},
            {"HOLO:ZUBOARD:DISABLE_CONTINOUS_STREAM", &SCPI_server::zuboard_disable_continous_stream},
            {"HOLO:ZUBOARD:SET_INTEG_TIME", &SCPI_server::zuboard_set_integration_time},
            {"HOLO:ZUBOARD:GET_INTEG_TIME", &SCPI_server::zuboard_get_integration_time},
        };

};
