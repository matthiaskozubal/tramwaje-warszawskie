
import urllib.request
from os.path import join, dirname
import dotenv
import json

def get_credentials(var, filename='.env'):
    path = join(dirname(__file__), filename)
    return dotenv.get_variable(path, var) # returns properly only if line with APIKEY is not the last one, insert empty line after it

def get_vehicles(data):
    def get_vehicle(item):
        return dict( [(item_values['key'],item_values['value']) for item_values in item['values']] )
    return [get_vehicle(item) for item in data['result']]

def main():
    response = urllib.request.urlopen('https://api.um.warszawa.pl/api/action/dbstore_get/?id=daeea0db-0f9a-498d-9c4f-210897daffd2&apikey=' + get_credentials('APIKEY')) # get page
    html   = response.read().decode('utf-8') # decode page # http://stackoverflow.com/questions/23049767/parsing-http-response-in-python
    data     = json.loads(html) # load string data to json # https://www.reddit.com/r/learnpython/comments/3nx9ch/json_load_vs_loads/
    vehicles = get_vehicles(data) # take all vehicles, keys: tabor, linia, gps_dlug, ostatnia_aktualizacja, gps_szer
    [print(vehicle['gps_dlug'],vehicle['gps_szer']) for vehicle in vehicles[:4]]

    with open('tramps_warsaw_json.txt', 'w') as output:
        output.write(html)

if __name__ == '__main__':
    main()


# geodata = [create_point(x['gps_dlug'], x['gps_szer'], x['linia']) for x in data]
# timedata = [x['ostatnia_aktualizacja'] for x in data]

# with open('tramwaje.json', 'w') as f:
#     f.write(json.dumps(geodata))

# print sorted(list(set(timedata)))

