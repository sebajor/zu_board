#include <string>
#include <arpa/inet.h>
#include <vector>
#include <iostream>



namespace UdpSocket{

int socket_config(int sock=-1, int sendsize=128, int recvsize=128, 
        int timeout=10, int reuse_addr=1);

int socket_creation(int timeout, int reuse_addr);
int setBuffer(int sock_fd, int sendsize, int recvsize);
sockaddr_in makeAddress(std::string_view ip, int port);
int bindSocket(int sock_fd, std::string_view ip, int port);
int closeSocket(int sock_fd);

//this is a raw implementation of the sendto (ie wo containers)
int sendTo(int sock_fd, 
        const void *data,
        size_t bytes,
        const sockaddr_in &addr);

int recvFrom(int sock_fd, 
        const void *data,
        size_t max_bytes,
        const sockaddr_in &src_addr);

//container sendto, recvfrom
template <typename T>
int sendTo(int sock_fd, std::vector<T> &data, sockaddr_in &addr){
    const T *raw = data.data();
    size_t bytes = data.size() * sizeof(T);
    int sent = sendto(sock_fd,
                      raw,
                      bytes,
                      0,
                      (const sockaddr *)&addr,
                      sizeof(addr));

    if (sent < 0) {
        std::cout << "UDP sendto error\n";
        return -1;
    }

    return sent / sizeof(T);   // elements sent
}

template <typename T>
int recvFrom(int sock_fd,
             std::vector<T> &buff,
             int max_len,
             sockaddr_in &src_addr)
{
    if ((int)buff.size() < max_len)
        buff.resize(max_len);

    socklen_t addr_len = sizeof(src_addr);

    int bytes = recvfrom(sock_fd,
                         buff.data(),
                         max_len * sizeof(T),
                         0,
                         (sockaddr *)&src_addr,
                         &addr_len);
    std::cout << "recv bytes:" <<bytes <<"\n";
    

    if (bytes == 0) {
        std::cout << "UDP socket closed\n";
        return 0;
    }
    if (bytes < 0) {
        if(errno == EAGAIN || errno == EWOULDBLOCK)
            return -2;  //timeout error
        else
            std::cout << "UDP recvfrom error\n";
            return -1;
    }

    buff.resize(bytes / sizeof(T));
    return bytes / sizeof(T);
}





}
