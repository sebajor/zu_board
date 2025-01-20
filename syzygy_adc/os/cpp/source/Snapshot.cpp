#include "../includes/Snapshot.h"
#include <iostream>
#include <sys/mman.h>
#include <cstdlib>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>



Snapshot::Snapshot(const std::string &binfile, const std::string &dev_mem,
    const axi_lite_reg &axil_reg, const axi_lite_reg &axil_bram){
    axil_reg_info = axil_reg;
    axil_bram_info = axil_bram;

    std::cout << "programming the FPGA\n";
    char helper[] = "fpgautil -b ";
    if(system(strcat(helper ,binfile.c_str()))){
            std::cout << "Problem programming the FPGA!!!\n";
            }
    std::cout << "openin the /dev/mem file\n";
    mem_fd = open(dev_mem.c_str(), O_RDWR);
    if(mem_fd==-1){
        std::cout << "cant open memory file!\n";
    }

    axil_reg_intf = static_cast<int*>(
        mmap(NULL,
            axil_reg_info.kernel_size,
            PROT_READ | PROT_WRITE,
            MAP_SHARED,
            mem_fd,
            axil_reg_info.page_offset
            )
        );
    axil_snapshot_intf = static_cast<int16_t*>(
        mmap(NULL,
            axil_bram_info.kernel_size,
            PROT_READ | PROT_WRITE,
            MAP_SHARED,
            mem_fd,
            axil_bram_info.page_offset
            )
        );
    //reset the system and enable adc
    *(axil_reg_intf)=1;
    *(axil_reg_intf)=0;
    *(axil_reg_intf)=2;
}

Snapshot::~Snapshot(){
    munmap(axil_reg_intf, axil_reg_info.kernel_size);
    munmap(axil_snapshot_intf, axil_bram_info.kernel_size);
    close(mem_fd);
}


int Snapshot::get_snapshot(
                std::vector<int16_t> &adc0,
                std::vector<int16_t> &adc1,
                int samples,
                int ms_sleep
                ){
    *(axil_reg_intf) = 0b010;
    *(axil_reg_intf) = 0b110;
    //sleep for a bit to have the complete waveform
    usleep(ms_sleep*100);
    for(int i=0; i<samples; ++i){
        adc0[i] = *(axil_snapshot_intf+2*i);
        adc1[i] = *(axil_snapshot_intf+2*i+1);
    }
    return 0;
}




