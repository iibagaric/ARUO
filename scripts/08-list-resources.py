import json
from pathlib import Path
from subprocess import check_output

from azure.identity import AzureCliCredential
from azure.mgmt.resource import ResourceManagementClient


def terraform_output(name: str) -> str:
    return check_output(["terraform", "-chdir=infra/terraform", "output", "-raw", name], text=True).strip()


subscription_id = json.loads(check_output(["az", "account", "show"], text=True))["id"]
resource_group = terraform_output("resource_group_name")

client = ResourceManagementClient(AzureCliCredential(), subscription_id)
resources = []

for item in client.resources.list_by_resource_group(resource_group):
    resources.append(
        {
            "name": item.name,
            "type": item.type,
            "location": item.location,
            "tags": item.tags,
            "id": item.id,
        }
    )

resources.sort(key=lambda r: (r["type"], r["name"]))

Path("evidence").mkdir(exist_ok=True)
Path("evidence/python-resource-list.json").write_text(json.dumps(resources, indent=2), encoding="utf-8")

for resource in resources:
    print(f"{resource['type']:<70} {resource['name']}")

