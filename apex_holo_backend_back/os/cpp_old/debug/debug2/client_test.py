import socket
import numpy as np

ip = '10.0.6.229'
port = 12235

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.connect((ip,port))

while(1):
    raw_data = sock.recv(1024)
    data = np.frombuffer(raw_data, 'f')
    print(data)


