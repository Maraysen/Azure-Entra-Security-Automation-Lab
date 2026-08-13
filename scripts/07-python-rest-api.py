import urllib.request
import urllib.error
import json

url = "https://api.github.com"

try:
    with urllib.request.urlopen(url) as response:
        data = json.load(response)

    print("API request successful.")
    print(data)

except urllib.error.HTTPError as error:
    print(f"HTTP error: {error.code}")

except urllib.error.URLError as error:
    print(f"Connection error: {error.reason}")

except Exception as error:
    print(f"Unexpected error: {error}")