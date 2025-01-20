#include <string>
#include <vector>

const int PAGE_SIZE = 4096;
const std::string mem_file {"/dev/mem"};
const int SNAPSHOT_SAMPLES = 1024;  //

struct axi_lite_reg {
    long page_offset =0;
    long internal_offset =0;
    int kernel_size = 0;
    int fpga_addr = 0;
};

class Snapshot{
    private:
        int mem_fd {-1};
        axi_lite_reg axil_reg_info {};
        axi_lite_reg axil_bram_info {};
        int* axil_reg_intf {};  //mem-mapped to axil_reg
        int16_t* axil_snapshot_intf {};

    public:
        //constructor
        Snapshot(const std::string &binfile, const std::string &dev_mem, 
                const axi_lite_reg &axil_reg, const axi_lite_reg &axil_bram);
        ~Snapshot();
        int get_snapshot(
                std::vector<int16_t> &adc0,
                std::vector<int16_t> &adc1,
                int samples=SNAPSHOT_SAMPLES,
                int ms_sleep=100
                );
};

