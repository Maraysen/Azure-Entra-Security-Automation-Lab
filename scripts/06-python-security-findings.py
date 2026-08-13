import json
import csv

with open("data/security-findings.json", "r") as file:
    findings = json.load(file)

results = []

for finding in findings:
    if finding["Risk"] >= 4:
        status = "REVIEW"
    else:
        status = "OK"

    result = {
        "Name": finding["Name"],
        "Risk": finding["Risk"],
        "Status": status
    }

    results.append(result)

with open("reports/python-security-findings.csv", "w", newline="") as file:
    writer = csv.DictWriter(
        file,
        fieldnames=["Name", "Risk", "Status"]
    )

    writer.writeheader()
    writer.writerows(results)

print("Python security findings report exported successfully.")