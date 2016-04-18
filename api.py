import urllib.request
from os.path import join, dirname
import dotenv
import json
import time
import csv

def get_credentials(var, filename='.env'):
    path = join(dirname(__file__), filename)
    return dotenv.get_variable(path, var) # returns properly only if line with APIKEY is not the last one, insert empty line after it

def get_vehicles(data):
    def get_vehicle(item):
        return dict( [(item_values['key'],item_values['value']) for item_values in item['values']] )
    return [get_vehicle(item) for item in data['result']]

def create_point(latitude, longitude, number):
    return {
            'type':          'Feature',
            'geometry':      {
                              'type':        'Point',
                              'coordinates': [latitude, longitude]
                             },
            'properties':    {
                              'marker-color': '#3ca0d3',            
                              'marker-symbol': number                        
                             }
           }

def main():
    response = urllib.request.urlopen('https://api.um.warszawa.pl/api/action/dbstore_get/?id=daeea0db-0f9a-498d-9c4f-210897daffd2&apikey=' + get_credentials('APIKEY')) # get page
    html   = response.read().decode('utf-8') # decode page # http://stackoverflow.com/questions/23049767/parsing-http-response-in-python
    data     = json.loads(html) # load string data to json # https://www.reddit.com/r/learnpython/comments/3nx9ch/json_load_vs_loads/
    vehicles = get_vehicles(data) # take all vehicles, keys: 'tabor,' 'linia', 'gps_dlug', 'ostatnia_aktualizacja', 'gps_szer'
    # with open('warsaw-tramps_' + time.strftime('%Y-%M-%d--%H-%M-%S'), 'w') as output:
    #     output.write(json.dumps(vehicles))

    vehicles_json = json.dumps(vehicles)    
            
    # with open('warsaw-tramps' + time.strftime('%Y.%M.%d_%H.%M.%S'), 'wb') as output_file_name:
    #     wr = csv.writer(output_file_name, quoting=csv.QUOTE_ALL)
    #     wr.writerow(vehicles)
    geodata = [create_point(vehicle['gps_dlug'], vehicle['gps_szer'], vehicle['linia']) for vehicle in vehicles]
    timedata = [x['ostatnia_aktualizacja'] for x in vehicles]
    return vehicles_json

main()


# print sorted(list(set(timedata)))

