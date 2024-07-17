import os.path
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup
import re
import json


def download_page(url):
    res = requests.get(url)
    return res.text

def parse_download_href(html_source, url):
    soup = BeautifulSoup(html_source, "html5lib")
    download_href =  soup.find('a', attrs={
        "title": "Download jetbra first"
    })["href"]

    download_url = urljoin(url, download_href)
    return download_url

def parse_ideas(html_source, code_dict):
    idea_list = []

    soup = BeautifulSoup(html_source, "html5lib")
    articles_soup = soup.find_all(name='article', attrs={'class': 'card'})
    for article_soup in articles_soup:
        name_ode = article_soup['data-sequence']
        version = article_soup.find('button')['data-version']
        idea_info = {
            'name': article_soup.find('h1').text,
            'nameCode': name_ode,
            'version': version,
            'code': code_dict[name_ode][version]
        }
        # print(article_soup['data-sequence'])
        idea_list.append(idea_info)
    return idea_list


def match_idea_code(html_resource):
    res_find = re.findall(r'jbKeys = (.*?);', html_resource)
    if len(res_find) == 0:
        exit("未匹配到激活码")
    res_code_str = res_find[0]
    res_dict = json.loads(res_code_str)
    return res_dict


def generate_index_md(ideas_list, download_href):
    h1 = '# JetBrain All Code'

    intr = "以上资源来自网络收集， 如有侵权请联系 demodeom@outlook.com 删除\n\n"
    package_str = "激活补丁存放在 **dist/** 目录下\n\n"

    code_s = '```'
    code_e = '```'

    with open('./readme.md', mode='w', encoding='utf-8') as f:
        f.write(h1 + '\n\n')

        f.write(intr)
        f.write(package_str)

        f.write(" 最新激活补丁压缩包：" + '\n\n')
        f.write(code_s + '\n')
        f.write(download_href.split("/")[-1] + '\n')
        f.write(code_e + '\n\n')

        for idea in ideas_list:
            h2 = "## " + idea['name'] + '  ' + idea['version']

            f.write(h2 + '\n\n')
            f.write(code_s + '\n')
            f.write(idea['code'] + '\n')
            f.write(code_e + '\n\n')

def dwonload_zip(download_href):
    file_name = "./dist/" + download_href.split("/")[-1]
    if os.path.exists(file_name) is False:
        f = open(file_name, "wb")
        res = requests.get(download_href)
        f.write(res.content)
        f.close()

if __name__ == '__main__':
    # url = "https://hardbin.com/ipfs/bafybeia4nrbuvpfd6k7lkorzgjw3t6totaoko7gmvq5pyuhl2eloxnfiri/"
    url = "https://bafybeih65no5dklpqfe346wyeiak6wzemv5d7z2ya7nssdgwdz4xrmdu6i.ipfs.dweb.link/"
    res_text = download_page(url)
    code_dict = match_idea_code(res_text)
    ideas_list = parse_ideas(res_text, code_dict)
    download_href = parse_download_href(res_text, url)
    generate_index_md(ideas_list, download_href)
    dwonload_zip(download_href)

