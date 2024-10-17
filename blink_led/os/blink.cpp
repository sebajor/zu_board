#include <iostream>
#include <sys/mman.h>
#include <signal.h>
#include <string>
#include <fcntl.h>      //this one has the O_RDWR flags and stuffs

const int PAGE_SIZE = 4096;
const std::string mem_file {"/dev/mem"};

struct axi_lite_reg{
    long page_offset = 0;
    long internal_offset = 0;
    int kernel_size = 0;
    int fpga_addr = 0;
};

long offset {0xA1100000};
long kernel_size {1024*32};
int mem_fd = -1;
int* axil_reg_intf;


void interrupt(int sig){
    std::cout << "free memory" << std::endl;//using endl flush the stdout
    munmap(axil_reg_intf, kernel_size);
    close(mem_fd);
    exit(1);
}

int turn_led_on(int* axi_reg_intf, axi_lite_reg &axi_info){
    *(axi_reg_intf+axi_info.internal_offset+1) |= 1;
    return 1;
}

int turn_led_off(int* axi_reg_intf, axi_lite_reg &axi_info){
    *(axi_reg_intf+axi_info.internal_offset+1) &= 0;
    return 1;
}


int main(){
    axi_lite_reg axi_info {
        .page_offset= (offset/PAGE_SIZE)*PAGE_SIZE,
        .internal_offset = offset%PAGE_SIZE,
        .kernel_size = 1024*32,
        .fpga_addr = 1024
    };

    std::cout << axi_info.page_offset << "  "
	    << axi_info.internal_offset << "\n"; 

    mem_fd = open(mem_file.c_str(), O_RDWR);
    if(mem_fd==-1){
        std::cout << "cant open memory file :(\n";
        return 1;
    }
    axil_reg_intf = static_cast<int*> (
            mmap(
                NULL,
                axi_info.kernel_size,
                PROT_READ | PROT_WRITE,
                MAP_SHARED,
                mem_fd,
                axi_info.page_offset
            )
        );
    signal(SIGINT, interrupt);

    while(1){
        turn_led_on(axil_reg_intf, axi_info);
        std::cout<< "turn on led\t" <<
            *(axil_reg_intf+axi_info.internal_offset+3) <<
            "\n"
            ;
        sleep(1);
        turn_led_off(axil_reg_intf, axi_info);
        std::cout<< "turn off led\t" <<
            *(axil_reg_intf+axi_info.internal_offset+3) <<
            "\n"
            ;
	sleep(1);
    };
    return 1;
}
