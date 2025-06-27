#include <string>
#include <array>

const int PAGE_SIZE = 4096;
const std::string mem_file {"/dev/mem"};
const int MAX_DFT_SIZE = 1024;
const int SNAPSHOT_SAMPLES = 1024;  //
const int TWIDDLE_POINT = 14;

struct axi_lite_reg {
    long page_offset =0;
    long internal_offset =0;
    int kernel_size = 0;
    int fpga_addr = 0;
};


class apexHoloBackend{
    private:
        long page_offset {0}, internal_offset {0};
        int mem_fd {-1}; //dev mem file descriptor
        int* axil_reg_intf {};  //mem-mapped to axilite register
        int* axil_bram_intf {};
        int16_t*  axil_snapshot_intf {};
        axi_lite_reg axi_reg_info {};
        axi_lite_reg axi_bram_info {};
        axi_lite_reg axi_snapshot_info {};
    public:
        apexHoloBackend(const std::string &binfile,const std::string &dev_mem, 
                const axi_lite_reg &axil_reg, const axi_lite_reg &axil_bram,
                const axi_lite_reg &snapshot_bram
                );
        //destructor
        ~apexHoloBackend();
        //
        int accumulation {-1};
        int dft_len {-1};
        int twiddle_number {-1};
        int twiddle_point {TWIDDLE_POINT};
        //
        int set_accumulation(int acc_len);
        int set_dft_len(int dft_len);

        int upload_twiddle_factors(
            int k,
            int twiddle_point
            );
        int enable_correlator();
        int check_data_available();
        int check_ack_error();
        int acknowledge_data();
        int get_register_data(std::array<float, 4> &read_values);
        int get_snapshot(
                std::array<int16_t, SNAPSHOT_SAMPLES> &adc0,
                std::array<int16_t, SNAPSHOT_SAMPLES> &adc1);
};
