import api
# import json
import pandas as pd
import numpy as np
import matplotlib
import matplotlib.pyplot as plt


data = api.current_data('warsaw-tramps_2016-15-17--17-15-59')


def veh_hist(): # Histogram for dlug i szer
## get_ipython().magic('matplotlib inline')
    fig1 = data[['gps_dlug', 'gps_szer']].hist(bins=30) # Dokładność gps'u?
    plt.show()
    # plt.pause(1)
    # plt.close

def veh_scatter_all(): # Scatter plot for dlug i szer
    fig2 = data.plot.scatter('gps_dlug', 'gps_szer')
    plt.show()


def veh_scatter_south():
    gps_dlug_south = data[data['gps_szer'] < 52.2330653]
    fig3 = gps_dlug_south.plot.scatter('gps_dlug', 'gps_szer')
    plt.show()


def veh_scatter_parts(steps = 10, sleep_time = 1):
    plt.axis([20.85, 21.15, 52.15, 52.35])
    plt.ion()
    for i in range(1, steps):
        step = (52.35 - 52.15)/i
        data_to_plot = data[data['gps_szer'] <= (52.15 + 2*i/100)]
    #     data_to_plot.plot.scatter('gps_dlug', 'gps_szer')
        try:
            fig4 = plt.scatter(data_to_plot['gps_dlug'], data_to_plot['gps_szer'])
        except TypeError:
            pass
        plt.show()
        plt.pause(sleep_time)


# Mean count
bin_vector = np.linspace(0,83,84)
bin_vector.astype(int)
'''
## Number of vehicles for a given line number
# data['linia'].hist(bins = max(data['linia']))
(n, bins, patches) = plt.hist(data['linia'], bins = bin_vector)

linie_data_series = pd.Series((bins.astype(int), n.astype(int)), index = ['linia', 'pojazdy'])
print(linie_data_series['linia'])
print(linie_data_series['pojazdy'])

def veh_mean(cutoff = '83'): # max(data[]'linia'])
    for i in range(0, cutoff):
        c = data['linia'].count(i)
        print(c)

# http://stackoverflow.com/questions/2600191/how-can-i-count-the-occurrences-of-a-list-item-in-python

#     pojazdy_all_mean = int(linie_data_series['pojazdy'].sum()/len(linie_data_series['pojazdy']))
# pojazdy_all_mean
veh_mean(5)

a=[linie_data_series['linia'] <= cutoff]
b=linie_data_series['linia'][[linie_data_series['linia'] <= cutoff]]
b


print(len(a[0]))
print(len(linie_data_series['linia']))
# length = len(linie_data_series['pojazdy'][linie_data_series['linia'] <= cutoff])
# pojazdy_part_mean = linie_data_series['pojazdy'][linie_data_series['linia'] <= cutoff].sum()/


# for i in range(1,4):
#     data = actual_data()
#     data.plot.scatter('gps_dlug', 'gps_szer')
#     time.sleep(3)
'''

# Plots ==========================================================
veh_scatter_parts(20, 0.5)
# ================================================================
