import os
import sys

import requests


def get_json(url):
    try:
        response = requests.get(url, verify=False)
        response.raise_for_status()
        data = response.json()
        return data
    except requests.exceptions.RequestException as e:
        raise SystemExit(e)


def get_host(route):
    host = route['rule']
    if host.startswith("Host") and not "Regexp" in host:
        return host
    else:
        return None


def get_addr(route, char):
    host = get_host(route)
    if host == None:
        return None
    start = host.index(char) + len(char)
    end = host.index(char, start)
    return host[start:end]


def check_file_exists(file_path):
    return os.path.exists(file_path)


def get_dns_records(file_path):
    data = {}
    with open(file_path, 'r') as f:
        for line in f:
            values = line.strip().split(' ')
            data[values[1]] = values[0]
    return data


def write_dns_records(file_path, addr, ip):
    with open(file_path, 'a') as f:
        f.write(ip + " " + addr + "\n")


if __name__ == "__main__":
    url = sys.argv[1]
    file_path = sys.argv[2]
    ip = sys.argv[3]

    if url.endswith("/"):
        url += "api/http/routers"
    else:
        url += "/api/http/routers"

    if not check_file_exists(file_path):
        raise Exception("Something wrong with file!")

    json = get_json(url)
    dns_records = get_dns_records(file_path)

    for route in json:
        if "rule" not in route:
            continue
        addr = get_addr(route, "`")
        if addr == None:
            continue
        if addr not in dns_records:
            print("Adding " + addr)
            write_dns_records(file_path, addr, ip)
