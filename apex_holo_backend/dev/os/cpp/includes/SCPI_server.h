#include <vector>
#include <utility>
#include <string>
#include "../includes/apexHoloBackend.h"
#include "../includes/TcpSocket.h"
#include "../includes/UdpSocket.h"
#include <mutex>
#include <atomic>


/*
 *  This code uses 2 sockets.There is one udp service that is in charge of configure
 *  the setup while the second socket is a tcp that streams the correlated data.
 *
 */
class SCPI_server{
    private:
        apexHoloBackend &fpga;
        std::mutex &mut;
        //for the tcp 
        int tcp_sock_fd {-1};
        sockaddr_in tcp_client_addr;
        std::string tcp_ip {};
        int tcp_port {12234};
        //for the udp server
        int udp_sock_fd {-1};
        std::vector<char> recv_buffer {0};
        std::string recv_msg {0};
        sockaddr_in udp_client_addr;
        int recv_len {0};
        std::atomic<int> data_flag = 0;
        std::atomic<int> alive = 1;


    public:
        SCPI_server(apexHoloBackend &apex_fpga, std::mutex &shared_mutex,
                std::string_view udp_ip, int udp_port,
                std::string &tcp_ip, int tcp_port,
                int timeout, int send_size, int recv_size, int reuse_addr);
        ~SCPI_server();
        std::string ans {0};

        //adc snapshots
        std::array<int16_t, SNAPSHOT_SAMPLES> adc0_snapshot{0};
        std::array<int16_t, SNAPSHOT_SAMPLES> adc1_snapshot{0};
        //dont remember why i need these ones..
        std::string adc0_str = std::string(SNAPSHOT_SAMPLES*sizeof(int16_t), '\0');;
        std::string adc1_str = std::string(SNAPSHOT_SAMPLES*sizeof(int16_t), '\0');;
        int adc_clock = 100*1e6;
        float integ_time = -1;

        int parse_recv_msg(std::string &recv_msg, std::string &ans_msg);
        int check_messages();
        int answer_request();
        
        //methods.. always returns a int that shows if the action was successfull
        //the msg is the received one, the out_msg is the string that will be send to the client

        int zuboard_set_acc(std::string &msg, std::string &out_msg );
        int zuboard_get_acc(std::string &msg, std::string &out_msg );
        int zuboard_set_dft_size(std::string &msg, std::string &out_msg );
        int zuboard_get_dft_size(std::string &msg, std::string &out_msg );
        int zuboard_set_twiddle(std::string &msg, std::string &out_msg );
        int zuboard_get_twiddle(std::string &msg, std::string &out_msg );
        int zuboard_get_snapshot(std::string &msg, std::string &out_msg );
        int zuboard_enable_corr(std::string &msg, std::string &out_msg );
        int zuboard_continous_stream(std::string &msg, std::string &out_msg);
        int zuboard_disable_continous_stream(std::string &msg, std::string &out_msg);
        int zuboard_set_integration_time(std::string &msg, std::string &out_msg);
        int zuboard_get_integration_time(std::string &msg, std::string &out_msg);
         int zuboard_get_reg(std::string &msg, std::string &out_msg );

        int zuboard_set_dest_ip(std::string &msg, std::string &out_msg);
        int zuboard_get_dest_ip(std::string &msg, std::string &out_msg);
        int zuboard_set_dest_port(std::string &msg, std::string &out_msg);
        int zuboard_get_dest_port(std::string &msg, std::string &out_msg);
        int zuboard_start_acquisition(std::string &msg, std::string &out_msg);



        //commands and its correspondent methods
        std::vector<std::pair<std::string, int(SCPI_server::*)(std::string&, std::string&)>> cmds {
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
            {"HOLO:ZUBOARD:SET_DEST_IP", &SCPI_server::zuboard_set_dest_ip},
            {"HOLO:ZUBOARD:GET_DEST_IP", &SCPI_server::zuboard_get_dest_ip},
            {"HOLO:ZUBOARD:SET_DEST_PORT", &SCPI_server::zuboard_set_dest_port},
            {"HOLO:ZUBOARD:GET_DEST_PORT", &SCPI_server::zuboard_get_dest_port},
            {"HOLO:ZUBOARD:START_ACQUISITION", &SCPI_server::zuboard_start_acquisition},
        };
};


