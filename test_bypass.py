import requests
import re
from urllib.parse import unquote

session = requests.Session()
ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
session.headers.update({
    'User-Agent': ua
})

# 1. Fetch challenge
r = session.get('https://desarambipuji-jember.com/api/surat')
html = r.text

# Extract ts
ts_match = re.search(r"\'ts\',\s*\'(\d+)\'", html)
ts = ts_match.group(1) if ts_match else None

# Extract action url l
l_match = re.search(r"l\s*=\s*\'(/[^\']+)\'", html)
action = l_match.group(1) if l_match else None

print('ts:', ts)
print('action:', action)

