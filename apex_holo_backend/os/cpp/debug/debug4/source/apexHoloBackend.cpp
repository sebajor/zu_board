#include "../includes/apexHoloBackend.h"
#include <iostream>
#include <cstdlib>
#include <sys/mman.h>
#include <string>
#include <fcntl.h>  //aliases for the protection flags
#include <array>
#include <stdint.h>
#include <cmath>
#include <complex>
#include <string.h>
#include <unistd.h> //open, close


// axil_reg[0]:
//      0:reset
//      1:enable_adc
//      2:enable_bram
//      3:enable_correaltor
//      4:correlator_ack
// axil_reg[1]: acc_len
// axil_reg[2]: delay_line
//
// axil_reg[3]: FREE
//
// axil_reg[4]:
//      0:correlator_valid 
//      1:correlator_ack_error
//      2:mmcm_locked
//      3:clk_align_frame_valid
//      4-7: bitslip
//
// axil_reg[5] : pow0_0
// axil_reg[6] : pow0_1
// axil_reg[7] : pow1_0
// axil_reg[8] : pow1_1
// axil_reg[9] : ab_real_0
// axil_reg[10]: ab_real_1
// axil_reg[11]: ab_imag_0
// axil_reg[12]: ab_imag_1



//class constructor
apexHoloBackend::apexHoloBackend(const std::string &binfile, const std::string &dev_mem, 
        const axi_lite_reg &axil_reg, const axi_lite_reg &axil_bram,
        const axi_lite_reg &snapshot_bram
            ){
    axi_reg_info = axil_reg;    //maybe this is wrong..can be a problem with the scope
    axi_bram_info = axil_bram;    //maybe this is wrong..can be a problem with the scope
    axi_snapshot_info = snapshot_bram;

    //get the mmap focused in the register..
    //TODO: program the FPGA before doing this!!!
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
            axi_reg_info.kernel_size,
            PROT_READ | PROT_WRITE,
            MAP_SHARED,
            mem_fd,
            axi_reg_info.page_offset
            )
        );

    axil_bram_intf = static_cast<int*>(
        mmap(NULL,
            axi_bram_info.kernel_size,
            PROT_READ | PROT_WRITE,
            MAP_SHARED,
            mem_fd,
            axi_bram_info.page_offset
            )
        );
    
    axil_snapshot_intf = static_cast<int16_t*>(
        mmap(NULL,
            axi_snapshot_info.kernel_size,
            PROT_READ | PROT_WRITE,
            MAP_SHARED,
            mem_fd,
            axi_snapshot_info.page_offset
            )
        );

    //reset the system and enable the adc
    *(axil_reg_intf) = 1;
    *(axil_reg_intf) = 0;
    *(axil_reg_intf) = 2;
}



apexHoloBackend::~apexHoloBackend(){
    munmap(axil_reg_intf, axi_reg_info.kernel_size);
    munmap(axil_bram_intf, axi_bram_info.kernel_size);
    close(mem_fd);
}


int apexHoloBackend::set_accumulation(int acc_len){
    *(axil_reg_intf+1) = acc_len;
    return (*(axil_reg_intf+1) != acc_len);
}

int apexHoloBackend::set_dft_len(int dft_len){
    *(axil_reg_intf+2) = dft_len;
    return (*(axil_reg_intf+2) != dft_len);
}

int apexHoloBackend::upload_twiddle_factors(
        int dft_len, 
        int k, 
        int twiddle_point
        ){
    if(dft_len>MAX_DFT_SIZE)
        return 1;
    std::complex <float> freq(0,0);
    const std::complex <float> j(0,1);
    //std::cout <<"dft_len:"<< dft_len << "\n";
    std::complex<double> a {0};
    for(int i=0; i<dft_len; ++i){
        freq.real(2*M_PI*k*i/dft_len);
        a  = std::exp(-j*freq);
        a *= pow(2, twiddle_point);
        *(axil_bram_intf+2*i) =  static_cast<int32_t>(a.imag());
        *(axil_bram_intf+2*i+1) = static_cast<int32_t>(a.real());
    }
    return 0;
}

int apexHoloBackend::enable_correlator(){
    uint32_t prev_value = static_cast<uint32_t>(*(axil_reg_intf));
    std::cout << prev_value << "\n";
    prev_value |= 1<<3;
    *(axil_reg_intf) = static_cast<int>(prev_value);
    std::cout <<prev_value << "\n";
    return 1;
}


int apexHoloBackend::check_data_available(){
    int data = *(axil_reg_intf+4);
    return (data & 1);
};
int apexHoloBackend::check_ack_error(){
    int data = *(axil_reg_intf+4);
    return ((data & 2)>>1);
};
int apexHoloBackend::acknowledge_data(){
    uint32_t prev = static_cast<uint32_t>(*(axil_reg_intf));
    *(axil_reg_intf) = static_cast<int>(prev | 0b10000);
    *(axil_reg_intf) = static_cast<int>(prev & ~static_cast<uint32_t>(0b10000)); //check this!!
    return 0;
};

int apexHoloBackend::get_register_data(std::array<double, 4> &read_values){
    /* When saving the data in an axilite register it uses a 32 bit register, 
     * but the data is 64bits wide, so we read it by 32bits steps and then 
     * translate to long and finally convert that long in a float to not waste
     * too much memory
     */
    int low, high {0};
    int64_t value {0};
    int base = 5;
    std::cout << "debug raw:";
    for(int i=0; i<4; ++i){
        low = *(axil_reg_intf+base+2*i);
        high = *(axil_reg_intf+base+2*i+1);
	//std::cout << low << " " << high << std::endl;
        //value = (static_cast<int64_t>(low)) | ((static_cast<int64_t>(high)<<32));
        value = (reinterpret_cast<uint32_t&>(low)) | ((static_cast<int64_t>(high)<<32));
	std::cout <<i <<" "<< value << " " << high << " " << low << "\n";
        read_values[i] = static_cast<double>(value);
    }
    std::cout << "\n";
    return 1;
}

int apexHoloBackend::get_snapshot(std::array<int16_t, SNAPSHOT_SAMPLES> &adc0,
        std::array<int16_t, SNAPSHOT_SAMPLES> &adc1
        ){
    for(int i=0; i<SNAPSHOT_SAMPLES; ++i){
        adc0[i] = *(axil_snapshot_intf+2*i);
        adc1[i] = *(axil_snapshot_intf+2*i+1);
    }
    return 0;
}

