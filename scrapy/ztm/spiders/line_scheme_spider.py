# -*- coding: utf-8 -*-
import scrapy
import pandas as pd

csv_dir_path = '/home/pawel/projects/tramwaje-warszawskie'

class LineSchemeSpiderSpider(scrapy.Spider):
    name = "line_scheme_spider"
    allowed_domains = ["ztm.waw.pl"]
    start_urls = (
        'http://www.ztm.waw.pl/rozklad_nowy.php?c=182&l=1&q=26',
    )

    def parse(self, response):
        data = {
            'stopName': [],
            'stopNum': [],
            'stopId': [],
            'stopLocalId': [],
            'stopDirection': [],
        }
        for direction in response.xpath('//*[@id="PrzystanekRozklad"]/table'):
            stop_link = direction.xpath('tr/td[@class="pn"]/a')
            stop_urls = stop_link.xpath('@href').extract()
            stop_names = stop_link.xpath('text()').extract()
            stop_data = [dict(x.split('=') for x in \
                s.replace('rozklad_nowy.php?','').split('&')) for s in stop_urls]
            data['stopName'].extend(stop_names)
            data['stopNum'].extend(range(len(stop_names)))
            data['stopId'].extend([x['n'] for x in stop_data])
            data['stopLocalId'].extend([x['o'] for x in stop_data])
            data['stopDirection'].extend([x['k'] for x in stop_data])
        df = pd.DataFrame.from_dict(data)
        df.to_csv('%s/line_scheme_26.csv' % csv_dir_path, encoding='utf-8', index=False)
