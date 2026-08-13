import urllib.request
import urllib.error
import json

base_url = "https://api.github.com/repos/octocat/Spoon-Knife/issues"
per_page = 5
page = 1
max_pages = 3

all_items = []

try:
    while page <= max_pages:
        url = f"{base_url}?per_page={per_page}&page={page}"

        print(f"Requesting page {page}...")

        with urllib.request.urlopen(url) as response:
            items = json.load(response)

        if not items:
            break

        all_items.extend(items)
        page += 1

    print(f"Retrieved {len(all_items)} items.")

except urllib.error.HTTPError as error:
    print(f"HTTP error: {error.code}")

except urllib.error.URLError as error:
    print(f"Connection error: {error.reason}")

except Exception as error:
    print(f"Unexpected error: {error}")