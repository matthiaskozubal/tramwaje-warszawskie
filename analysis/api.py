import urllib2
import json

def get_vehicles(data):
    def get_vehicle(obj):
        return dict([(x['key'], x['value']) for x in obj['values']])
    return [get_vehicle(x) for x in data['result']]

def create_point(v_lat, v_long, v_number):
    return {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [v_lat, v_long]
        },
        "properties": {
          "marker-color": "#3ca0d3",
          "marker-symbol": v_number
        }
      }

response = urllib2.urlopen('https://api.um.warszawa.pl/api/action/dbstore_get/?id=daeea0db-0f9a-498d-9c4f-210897daffd2&apikey=f10fec28-bf17-4abd-94d7-7b42ac4ab33e')
data = get_vehicles(json.load(response))
geodata = [create_point(x['gps_dlug'], x['gps_szer'], x['linia']) for x in data]
timedata = [x['ostatnia_aktualizacja'] for x in data]

with open('tramwaje.json', 'w') as f:
    f.write(json.dumps(geodata))

print sorted(list(set(timedata)))

