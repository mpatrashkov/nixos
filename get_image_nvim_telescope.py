import urllib.request
import json
import re

query = 'repo:3rd/image.nvim "telescope"'
url = f"https://api.github.com/search/issues?q={urllib.parse.quote(query)}"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode())
        for item in data.get('items', []):
            print(f"#{item['number']}: {item['title']} - {item['html_url']}")
except Exception as e:
    print(f"Error: {e}")
