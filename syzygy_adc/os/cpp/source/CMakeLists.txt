cmake_minimum_required(VERSION 3.13)
project(adc_snapshot)

##include dir
include_directories(${CMAKE_SOURCE_DIR}i/../includes/)

add_executable(${PROJECT_NAME} 
    main.cpp
    TcpSocket.cpp
    SCPI_server.cpp
    TcpServer.cpp
    Snapshot.cpp
)



