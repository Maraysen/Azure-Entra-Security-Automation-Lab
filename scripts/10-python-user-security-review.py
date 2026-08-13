import os
import urllib.request
import urllib.error
import json
import csv

token = os.environ["GRAPH_TOKEN"]

url = (
    "https://graph.microsoft.com/v1.0/users"
    "?$select=id,displayName,userPrincipalName,accountEnabled"
)

request = urllib.request.Request(
    url,
    headers={
        "Authorization": f"Bearer {token}"
    }
)

results = []

try:
    with urllib.request.urlopen(request) as response:
        data = json.load(response)

    for user in data["value"]:

        if user["accountEnabled"] is False:
            status = "REVIEW"
            reason = "Account is disabled"
        else:
            status = "OK"
            reason = "Account is enabled"

        results.append({
            "DisplayName": user["displayName"],
            "UserPrincipalName": user["userPrincipalName"],
            "AccountEnabled": user["accountEnabled"],
            "Status": status,
            "Reason": reason
        })

    with open("reports/python-user-security-review.csv", "w", newline="") as file:
        writer = csv.DictWriter(
            file,
            fieldnames=[
                "DisplayName",
                "UserPrincipalName",
                "AccountEnabled",
                "Status",
                "Reason"
            ]
        )

        writer.writeheader()
        writer.writerows(results)

    print("User security review completed.")

    for result in results:
        print(
            f"{result['DisplayName']} - "
            f"{result['Status']} - "
            f"{result['Reason']}"
        )

except urllib.error.HTTPError as error:
    print(f"HTTP error: {error.code}")

except urllib.error.URLError as error:
    print(f"Connection error: {error.reason}")

except Exception as error:
    print(f"Unexpected error: {error}")