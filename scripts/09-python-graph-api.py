import os
import urllib.request
import urllib.error
import json

token = os.environ["GRAPH_TOKEN"]

url = "https://graph.microsoft.com/v1.0/users?$top=5"

request = urllib.request.Request(
    url,
    headers={
        "Authorization": f"Bearer {token}"
    }
)

try:
    with urllib.request.urlopen(request) as response:
        data = json.load(response)

    print("Microsoft Graph request successful.")

    for user in data["value"]:
        print(user["displayName"])

except urllib.error.HTTPError as error:
    print(f"HTTP error: {error.code}")

except urllib.error.URLError as error:
    print(f"Connection error: {error.reason}")

except Exception as error:
    print(f"Unexpected error: {error}")