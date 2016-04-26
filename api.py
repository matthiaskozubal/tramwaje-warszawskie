import urllib.request
from os.path import join, dirname
import dotenv
import json
import pandas as pd
import time
import csv


def get_credentials(var, filename='.env'):
    path = join(dirname(__file__), filename)
    return dotenv.get_variable(path, var) # returns properly only if line with APIKEY is not the last one, insert empty line after it


def get_data_web():
    response = urllib.request.urlopen('https://api.um.warszawa.pl/api/action/dbstore_get/?id=daeea0db-0f9a-498d-9c4f-210897daffd2&apikey=' + get_credentials('APIKEY')) # get page
    html     = response.read().decode('utf-8') # decode page # http://stackoverflow.com/questions/23049767/parsing-http-response-in-python
    data_web = json.loads(html) # load string data to json # https://www.reddit.com/r/learnpython/comments/3nx9ch/json_load_vs_loads/
    return data_web


def get_data_vehicles(data_web):
    def get_vehicle(item):
        return dict( [(item_values['key'],item_values['value']) for item_values in item['values']] )
    return [get_vehicle(item) for item in data_web['result']]


## Generate data in pandas from vehicle data dumped to json - from web directly or from file
def current_data(filename = None):
    if filename == None:
        data_web = get_data_web()
        data_veh = get_data_vehicles(data_web) # take all vehicles, keys: 'tabor,' 'linia', 'gps_dlug', 'ostatnia_aktualizacja', 'gps_szer'
        data_veh_json = json.dumps(data_veh)
        data = pd.read_json(data_veh_json)
    elif filename is not None:
        data = pd.read_json(filename)
    return data


def save_data_web():
    with open('warsaw-tramps_' + time.strftime('%Y-%M-%d--%H-%M-%S'), 'w') as output:
        output.write(json.dumps(data_web))


def save_data_veh():
    with open('warsaw-tramps' + time.strftime('%Y.%M.%d_%H.%M.%S'), 'wb') as output_file_name:
        wr = csv.writer(output_file_name, quoting=csv.QUOTE_ALL)
        wr.writerow(data_veh)
