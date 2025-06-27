#include "../includes/TcpSocket.h"
#include <iostream>
#include <string>
#include <arpa/inet.h>
#include <vector>
#include <netdb.h>
#include <errno.h>
#include <cstring>

namespace TcpSocket {

int socket_config(int sock, int sendsize, int recvsize, 
        int timeout, int reuse_addr){
    int sock_fd = -1;
    if(sock==-1){
        sock_fd = socket_creation(timeout, reuse_addr);
    }
    else
        sock_fd = sock;
    setBuffer(sock_fd, sendsize, recvsize);
    return sock_fd;
}

int socket_creation(int timeout, int reuse_addr){
    /*  
     *  Create a simple socket 
     */
    struct timeval sock_timeout {};
    struct linger sock_linger {};   //behavior when closing tehe socket
    const int enable = 1;

    int sock_fd = socket(AF_INET, SOCK_STREAM, 0);
    if(sock_fd<0)
        return -1;
    if(timeout<0)
        timeout =0;
    sock_timeout.tv_sec = timeout;
    if(setsockopt(sock_fd, SOL_SOCKET, SO_SNDTIMEO, &sock_timeout, sizeof(struct timeval)))
        return -1;
    if(setsockopt(sock_fd, SOL_SOCKET, SO_RCVTIMEO, &sock_timeout, sizeof(struct timeval)))
        return -1;
    if(setsockopt(sock_fd, SOL_SOCKET, SO_KEEPALIVE, & enable, sizeof(int)))
        std::cout << "socket keep-alive not set!\n";
    //set linger
    sock_linger.l_onoff = timeout>0;
    sock_linger.l_linger = (timeout>0) ? timeout:0;
    if(setsockopt(sock_fd, SOL_SOCKET, SO_LINGER, &sock_linger, sizeof(struct linger)))
        return -1;
    
    if(reuse_addr){
        if(setsockopt(sock_fd, SOL_SOCKET, SO_REUSEADDR | SO_REUSEPORT, &enable, sizeof(int))){
            std::cout << "error setting reuse addr";
        }
    }
    return sock_fd;
}

int setBuffer(int sock_fd, int sendsize, int recvsize){
    int send = setsockopt(sock_fd, SOL_SOCKET, SO_SNDBUF, &sendsize, sizeof(int));
    int recv = setsockopt(sock_fd, SOL_SOCKET, SO_RCVBUF, &recvsize, sizeof(int));
    return (send | recv);
}


int connectSocket(int sock_fd, std::string_view host, int port){
    struct sockaddr_in address {};
    /* method1
    struct addrinfo hints {0};
    struct addringo *res;
    hints.ai_family = AF_INET;  // use IPv4 or IPv6, whichever
    hints.ai_socktype = SOCK_STREAM;
    getaddrinfo(
            static_cast<const char*>(host.data()),
            static_cast<const char*>(std::to_string(port).data()),
            static_cast<const struct addrinfo* >(&hints),
            &res
            );
    */
    //method2
    //struct hostent  *server;
    //server = gethostbyname(host.data());
    //memcpy(&address.sin_addr.s_addr, server->h_addr, server->h_length);


    if(inet_pton(AF_INET, host.data(), &(address.sin_addr))){
        std::cout << "Error getting address\n";
        //return -1;
    }
    address.sin_family = AF_INET;
    address.sin_port = htons(port);
    //try to connect 
    if(connect(sock_fd, (struct sockaddr *)&address, sizeof(address))){
        std::cout << "Error connecting to the address\n";
        return -1;
    }
    return 0;
}

int bindListenSocket(int sock_fd, std::string_view ip, int port, int backlog){
    sockaddr_in address {};
    if(inet_pton(AF_INET, ip.data(), &(address.sin_addr))!=1){
        std::cout << "Error getting address\n";
        return -1;
    }
    address.sin_family = AF_INET;
    address.sin_port = htons(port);
    //try to get the port
    if(bind(sock_fd, (struct sockaddr *)&address, sizeof(address))){
	std::cout << "error " << strerror(errno) << "\n";
        std::cout << "Error binding socket\n";
        return -1;
    }
    //listen for incomming connections
    if(listen(sock_fd, backlog)){
        std::cout << "Error listening\n";
        return -1;
    }
    return 0;
}


int acceptConnection(int sock_fd, sockaddr &client_addr){
    socklen_t addr_size = sizeof(client_addr);
    int client_sock = accept(sock_fd, (struct sockaddr *) &client_addr, &addr_size);
    return client_sock;
}

int closeSocket(int sock_fd){
    std::cout << "destroying the socket "<< sock_fd <<std::endl;
    if(~(sock_fd))
        shutdown(sock_fd, SHUT_RD);
    return 0;
}



}
