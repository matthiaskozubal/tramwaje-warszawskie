import os
import api
import pandas
import matplotlib.pyplot as plt
# matplotlib.use('TkAgg')
import time


def plot1(i):
    # data[['gps_dlug', 'gps_szer']].hist()
    data_i = data[:i*2]
    fig = data_i.plot.scatter('gps_dlug', 'gps_szer')
    plt.show(fig)    
    time.sleep(1)
    plt.close(fig)


def plot2(i):
    plt.ion()
    # data[['gps_dlug', 'gps_szer']].hist()
    data_i = data[:i*2]
    plt.scatter(data['gps_dlug'], data['gps_szer'])
    plt.pause(5)


i = 0
for i in range(1,10):
    vehicles_json = api.main()
    data = pandas.read_json(vehicles_json)
    plot2(i)
    i += 1



