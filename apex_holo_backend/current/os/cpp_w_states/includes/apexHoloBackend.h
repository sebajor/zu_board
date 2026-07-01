#include <string>
#include <array>
#include <utility>
#include <chrono>
#include <vector>

const int PAGE_SIZE = 4096;
const std::string mem_file {"/dev/mem"};
const int MAX_DFT_SIZE = 1024;
const int SNAPSHOT_SAMPLES = 1024;  //
const int TWIDDLE_POINT = 14;
const int clock_hz = 100000000;
constexpr int RING_MAX_ADDR = static_cast<int>(((1<<14)/5))*5;

struct axi_lite_reg {
    long page_offset =0;
    long internal_offset =0;
    int kernel_size = 0;
    int fpga_addr = 0;
};


struct sync_timing {
    uint64_t initial_counter = 0;
    std::chrono::system_clock::time_point os_time;
};


class apexHoloBackend{
    private:
        long page_offset {0}, internal_offset {0};
        int mem_fd {-1}; //dev mem file descriptor
        volatile int* axil_reg_intf {};  //mem-mapped to axilite register
        volatile int* axil_bram_intf {};
        volatile int16_t*  axil_snapshot_intf {};
        volatile int64_t* axil_ring_intf {};
        axi_lite_reg axi_reg_info {};
        axi_lite_reg axi_bram_info {};
        axi_lite_reg axi_snapshot_info {};
        axi_lite_reg axi_ring_info {};
        int ring_buffer_read_pointer {0};
        int ring_limit_addr = RING_MAX_ADDR;
        //CHECK THE DATATYPE OF THE TIMESTAMP!!
        sync_timing initial_stamp;
        //std::pair<int64_t, int32_t> initial_stamp {};   //the first is the system timestamp in us, is the first value of the counter
    public:
        apexHoloBackend(const std::string &binfile,const std::string &dev_mem,
                const axi_lite_reg &axil_reg, const axi_lite_reg &axil_bram,
                const axi_lite_reg &snapshot_bram, const axi_lite_reg &axi_ring
                );
        //destructor
        ~apexHoloBackend();
        //
        int accumulation {-1};
        int dft_len {-1};
        int twiddle_number {-1};
        int twiddle_point {TWIDDLE_POINT};
        int fpga_clock_hz {clock_hz};   
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
        int get_register_data(std::array<uint64_t, 4> &read_values);
        int get_snapshot(
                std::array<int16_t, SNAPSHOT_SAMPLES> &adc0,
                std::array<int16_t, SNAPSHOT_SAMPLES> &adc1);
        //TODO!!!
        uint32_t get_ring_buffer_pointer();
        int get_ring_buffer_data(std::vector<int64_t> &ring_data);
        std::chrono::system_clock::time_point counter2timestamp(uint64_t curr_counter);


};

