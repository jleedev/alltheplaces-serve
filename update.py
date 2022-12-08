import json
import logging
from pathlib import Path, PurePath
import shutil
import tarfile
from urllib.parse import urlsplit
import zipfile

import requests

logging.basicConfig(format="%(asctime)s %(message)s")
logging.getLogger().setLevel(logging.DEBUG)
logging.info("starting up")

latest_url = "https://data.alltheplaces.xyz/runs/latest.json"

possible_output_path = [Path("output.tar.gz"), Path("output.zip")]
run_id_path = Path("run_id.txt")


def fetch_output():
    logging.info("fetching %s", latest_url)
    session = requests.Session()
    r = session.get(latest_url)
    r.raise_for_status()

    output_url = r.json()["output_url"]
    logging.info(f"{output_url=}")

    path = PurePath(urlsplit(output_url).path)
    run_id = path.parts[-2]
    run_id_path.write_text(
        f'<a href="https://www.alltheplaces.xyz/">All The Places</a> {run_id}'
    )

    r = session.get(output_url, stream=True)
    r.raise_for_status()
    output_path = Path(path.parts[-1])
    assert output_path in possible_output_path
    with output_path.open("wb") as f:
        shutil.copyfileobj(r.raw, f)
    return output_path


def extract(path):
    logging.info("extracting from %s", path)
    if path == Path("output.tar.gz"):
        it = open_tarball(path)
    elif path == Path("output.zip"):
        it = open_zipfile(path)
    else:
        raise ValueError(path)
    for r in it:
        try:
            j = json.load(r)
            yield from j["features"]
        except json.decoder.JSONDecodeError as e:
            logging.error("invalid json")


def open_tarball(path):
    with tarfile.open(path) as t:
        for entry in t:
            logging.info("process %s", entry.path)
            if not entry.path.endswith(".geojson"):
                logging.info("ignore")
                continue
            if entry.size == 0:
                logging.info("empty file")
                continue
            yield t.extractfile(entry)


def open_zipfile(path):
    with zipfile.ZipFile(path) as z:
        for info in z.infolist():
            if info.is_dir():
                continue
            logging.info("process %s", info.filename)
            if not info.filename.endswith(".geojson"):
                logging.info("ignore")
                continue
            if info.file_size == 0:
                logging.info("empty file")
                continue
            yield z.open(info)


for p in possible_output_path:
    if p.is_file():
        logging.info("have %s", p)
        output_path = p
        break
else:
    output_path = fetch_output()


for feature in extract(output_path):
    if "geometry" not in feature:
        logging.error("no geometry")
        continue
    [longitude, latitude] = feature["geometry"]["coordinates"]
    if [latitude, longitude] == [0, 0]:
        logging.error("null island")
        continue
    if not -85.05112878 < latitude < 85.05112878:
        logging.error("latitude out of range")
        continue
    if not -180 < longitude < 180:
        logging.error("longitude out of range")
        continue
    print(json.dumps(feature))


logging.info("done")
