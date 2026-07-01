#include "../includes/SCPI_server.h"
#include <iostream>
#include <cerrno>
#include <cstring>



int main(){

    const std::string binfile {"/home/root/apex_holo/fpga.bin"};
    const std::string dev_mem {"/dev/mem"};
     
    int scpi_port {12234};
    std::string_view scpi_host {"0.0.0.0"};

    int tcp_port {12334};
    std::string_view tcp_ip {"0.0.0.0"};
    
    int offset = 0xA0008000;
    axi_lite_reg axi_reg_info {
        .page_offset = (0xA0008000/PAGE_SIZE)*PAGE_SIZE,
        .internal_offset = 0xA0008000%PAGE_SIZE,
        .kernel_size=32*1024,
        .fpga_addr=1024
    };

    offset = 0xA0000000;
    axi_lite_reg axi_snapshot_bram {
        .page_offset = (0xA0000000/PAGE_SIZE)*PAGE_SIZE,
        .internal_offset = 0xA0000000%PAGE_SIZE,
        .kernel_size=32*1024,
        .fpga_addr=1024
    };

    offset = 0xA0010000;
    axi_lite_reg axi_twiddle_bram {
        .page_offset = (0xA0010000/PAGE_SIZE)*PAGE_SIZE,
        .internal_offset = 0xA0010000%PAGE_SIZE,
        .kernel_size=32*1024,
        .fpga_addr=1024
    };

    offset = 0xA0080000;
    axi_lite_reg axi_ring_bram{
        .page_offset = (0xA0080000/PAGE_SIZE)*PAGE_SIZE,
        .internal_offset = 0xA0080000%PAGE_SIZE,
        .kernel_size=512*1024,
        .fpga_addr=16384
    };

    fpga_parameters default_parameters {
        .accumulation =195,
        .dft_size = 1024,
        .integration_time = 1024.0*195/(100*1e6),
        .twiddle_factor =219,
        .adc_clock = 100*1e6,
    };

    

    int recv_bytes = 0;
    std::string ans;
    
    
    SCPI_server serv(
                    scpi_host,
                    scpi_port,
                    tcp_ip,
                    tcp_port,
                    binfile,
                    dev_mem,
                    axi_reg_info,
                    axi_twiddle_bram,
                    axi_snapshot_bram,
                    axi_ring_bram,
                    default_parameters
                    );

    while(1){
        recv_bytes = serv.check_message();
        if(recv_bytes>0){
            std::cout << "got some message "<<recv_bytes << "\n";
            for(int i=0; i<recv_bytes; ++i){
                std::cout << serv.buffer[i];
            }
            serv.parse_recv_message(serv.buffer, recv_bytes, ans);
            std::cout << "answering:\n";
            std::cout << ans << "\n";
            serv.answer_request(ans);
        }
        if(recv_bytes==-1){
            std::cout <<"errno:"<< strerror(errno) << "\n";
        }
    }
    return 0;
}
