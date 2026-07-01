#cmake_minimum_required(VERSION 3.25)
project(scpi_server)

set(CMAKE_BUILD_TYPE Debug)

include_directories(../includes)

add_executable(${PROJECT_NAME} 
    main.cpp
    SCPI_server.cpp
    UdpSocket.cpp
    TcpSocket.cpp
    apexHoloBackend.cpp
)


