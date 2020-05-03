#!/usr/bin/env python3
'''
Script to get configs

Usage:
    get_config.py
'''
import os
import sys
import re
from html.parser import HTMLParser
from multiprocessing import Process, Queue, current_process, freeze_support
import requests

class ConfigContext:
    '''
    Global configs
    '''
    def __init__(self):
        '''
        Initialize global configs.
        '''
        self.download_dir = self.environ_or_default('DOWNLOAD_DIR', '/opt')
        self.process_count = self.environ_or_default('NUMBER_OF_PROCESSES', '5')
        self.url_list = []

    @classmethod
    def environ_or_default(cls, env, def_value):
        '''
        Get the variable from environment or default
        '''
        try:
            return os.environ[env]
        except KeyError:
            return def_value

    @classmethod
    def environ_or_die(cls, env):
        '''
        Get the variable from environment or die
        '''
        try:
            return os.environ[env]
        except KeyError:
            print('Missing {envvar} in environment.'.format(envvar=env))
            sys.exit(1)

class URLParser(HTMLParser):
    '''
    Custom class inherited from HTMLParser to parse
    urls from web pages
    '''
    def __init__(self):
        '''
        init method inheriting parent class init method
        '''
        HTMLParser.__init__(self)
        self.links = []
        self.parent_url = ''

    def feed_parent_url(self, url):
        '''
        Function to set the parent url to the class object
        '''
        self.parent_url = url

    def handle_starttag(self, tag, attrs):
        '''
        Functions to get urls based on certain criteria
        Get only urls under the parent
        Get urls as full url including parent url (if provided)
        '''
        if tag != 'a':
            return
        for attr in attrs:
            if 'href' in attr[0]:
                if attr[1] == '../':
                    continue
                if self.parent_url:
                    if re.match(r'^http', attr[1]):
                        if re.match(self.parent_url, attr[1]):
                            self.links.append(attr[1])
                        else:
                            continue
                    else:
                        self.links.append('{0}/{1}'.format(self.parent_url.rstrip('/'), attr[1].lstrip('/')))
                else:
                    self.links.append(attr[1])
                break

def url_extracter(url):
    '''
    Function to extract sub urls from a give web url
    It used the URLParser class
    '''
    parser = URLParser()
    r_res = requests.get(url)
    parser.feed_parent_url(url)
    parser.feed(r_res.text)
    return parser.links

def url_crawler(url):
    '''
    Function to crawl through web including sub sites and collect all urls
    under the same parent url
    '''
    urls = url_extracter(url)
    for each_url in urls:
        r_head = requests.head(each_url)
        if re.match(r'^http.*?\.ovpn$', each_url.lower()):
            CONFIG.url_list.append(each_url)
        elif r_head.headers['Content-Type'] == 'text/html':
            url_crawler(each_url)
        else:
            CONFIG.url_list.append(each_url)

def download_url(url):
    '''
    Function to download a url as file
    '''
    if re.match(r'.*?\.ovpn', url):
        path_split = url.split('/')
        if path_split[-2].lower() == 'tcp':
            download_path = '{0}/{1}'.format(CONFIG.download_dir, 'tcp')
        elif path_split[-2].lower() == 'udp':
            download_path = '{0}/{1}'.format(CONFIG.download_dir, 'udp')
        else:
            download_path = '{0}'.format(CONFIG.download_dir)
        if not os.path.isdir(download_path):
            os.makedirs(download_path)
        r_res = requests.get(url, stream=True)
        file_path = '{0}/{1}'.format(download_path, path_split[-1])
        with open(file_path, 'wb') as f_handle:
            for chunk in r_res:
                f_handle.write(chunk)
        return 'Success'

def worker(in_queue, out_queue):
    '''
    Worker function to allocate taks to function
    '''
    for func, arg in iter(in_queue.get, 'STOP'):
        result = download(func, arg)
        out_queue.put(result)

def download(func, arg):
    '''
    Function to download and return result
    '''
    result = func(arg)
    return '%s=%s' % (arg, result)


def main(url):
    '''
    Main functions
    '''
    url_list = []
    url_crawler(url)
    for each_url in CONFIG.url_list:
        if re.match(r'^http.*?openvpn.*?\.ovpn$', each_url.lower()):
            url_list.append(tuple([download_url, each_url]))

    # Create queues
    download_queue = Queue()
    complete_queue = Queue()

    # Submit tasks
    for item in url_list:
        download_queue.put(item)

    # Start worker processes
    for i in range(CONFIG.process_count):
        Process(target=worker, args=(download_queue, complete_queue)).start()

    # Get and print results
    print('Results:')
    for i in range(len(url_list)):
        print('\t', complete_queue.get())

    # Tell child processes to stop
    for i in range(CONFIG.process_count):
        download_queue.put('STOP')

if __name__ == '__main__':
    freeze_support()
    CONFIG = ConfigContext()
    main('https://vpn.hidemyass.com/vpn-config')
