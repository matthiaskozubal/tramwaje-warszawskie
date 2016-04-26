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


geodata = [create_point(vehicle['gps_dlug'], vehicle['gps_szer'], vehicle['linia']) for vehicle in vehicles]
timedata = [x['ostatnia_aktualizacja'] for x in vehicles]
# print sorted(list(set(timedata)))
