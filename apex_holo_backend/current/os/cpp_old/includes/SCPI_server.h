#include "TcpServer.h"
#include <vector>
#include <string>
#include <map>
#include <functional>


class SCPI_server: public TcpServer {
    public:
        //The best should be to have a mapping<string, func> but I couldnt manage
        //to make it..
        int internal_value = -1;
        std::vector<std::string_view> cmds {
            "HOLO:ZUBOARD:SET_ACC",
            "HOLO:ZUBOARD:GET_REG",
            "HOLO:ZUBOARD:GET_SNAPSHOT",
            "HOLO:ZUBOARD:ENABLE_CORR",
            "HOLO:ZUBOARD:SET_DFT_SIZE",
            "HOLO:ZUBOARD:SET_TWIDDLE",
        };
        SCPI_server(std::string_view ip, int port);
        ~SCPI_server();
        int parse_recv_msg(std::string_view input_data, float &arg, std::vector<std::string_view> &scpi_cmds);
        //methods
        int SCPI_help(float &args, std::string &msg);
        int SCPI_set_integer(float &args, std::string &msg);
        int SCPI_get_integer(float &args, std::string &msg);
};
