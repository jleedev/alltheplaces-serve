import json
import logging
from pathlib import Path
import shutil
import tarfile
import urllib.parse

from bs4 import BeautifulSoup
import requests

logging.basicConfig(format='%(asctime)s %(message)s')
logging.getLogger().setLevel(logging.DEBUG)
logging.info('starting up')

latest_embed = 'https://data.alltheplaces.xyz/runs/latest/info_embed.html'

output_path = Path('output.tar.gz')
run_id_path = Path('run_id.txt')

def fetch_output():
    logging.info('fetching %s', latest_embed)
    session = requests.Session()
    r = session.get(latest_embed)
    r.raise_for_status()
    soup = BeautifulSoup(r.text, 'html.parser')

    output_url = soup.find('a')['href']
    logging.info(f'{output_url=}')

    run_id = Path(urllib.parse.urlparse(output_url).path).parts[-2]
    run_id_path.write_text(f'<a href="https://www.alltheplaces.xyz/">All The Places</a> {run_id}')

    r = session.get(output_url, stream=True)
    r.raise_for_status()
    with output_path.open('wb') as f:
        shutil.copyfileobj(r.raw, f)

def extract(path):
    logging.info('extracting from %s', path)
    t = tarfile.open(path)
    for entry in t:
        logging.info('process %s', entry.path)
        if not entry.path.endswith('.geojson'):
            logging.info('ignore')
            continue
        if entry.size == 0:
            logging.info('empty file')
            continue
        try:
            j = json.load(t.extractfile(entry))
            yield from j['features']
        except json.decoder.JSONDecodeError as e:
            logging.error('invalid json')


if not output_path.is_file():
    fetch_output()

for feature in extract(output_path):
    if "geometry" not in feature:
        logging.error('no geometry')
        continue
    [longitude, latitude] = feature["geometry"]["coordinates"]
    if [latitude, longitude] == [0, 0]:
        logging.error('null island')
        continue
    if not -85.05112878 < latitude < 85.05112878:
        logging.error('latitude out of range')
        continue
    if not -180 < longitude < 180:
        logging.error('longitude out of range')
        continue
    print(json.dumps(feature))


logging.info('done')


