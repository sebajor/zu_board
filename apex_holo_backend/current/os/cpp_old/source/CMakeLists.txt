#cmake_minimum_required(VERSION 3.25)
project(scpi_server)

include_directories(../includes)

add_executable(${PROJECT_NAME} 
    main.cpp
    SCPI_server.cpp
    UdpSocket.cpp
    TcpSocket.cpp
    apexHoloBackend.cpp
)


