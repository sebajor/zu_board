import pandas as pd

def read_xdc(filename):
    data  = {}
    f = open(filename, 'r')
    for line in f.readlines():
        if 'PACKAGE_PIN' in line:
            l = line.split(' ')
            pin = l[2]
            name = l[4][:-1]
            data[name] = pin
    f.close()
    return data


pins = pd.read_csv('pins.csv')
xdc_data = read_xdc('../fpga.xdc')

for name, pin in zip(pins['XDC name'], pins['fpga']):
    test = xdc_data[name]
    if(test!= pin):
        print("Error: %s %s != %s"%(name, pin, test))


