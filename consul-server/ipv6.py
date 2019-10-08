import commands
import json
import sys


# curl -X POST \
#   http://internal.api.ucloud.cn \
#   -H 'Content-Type: application/json' \
#   -H 'cache-control: no-cache' \
#   -d '{
#     "Action": "IGetResourceInfo",
#     "Backend": "UResource",
#     "ResourceId":"uhost-43uhr1",
#     "GenerateType": 0,
#     "RegionId": 1000003
# }'

resp1 = '''{
    "RetCode": 0,
    "Action": "IGetResourceInfo",
    "Infos": [
        {
            "Id": "uhost-43uhr1",
            "ResourceId": "9709d0b6-0ee2-4a2f-878b-329ae2b86642",
            "RegionId": 1000003,
            "ZoneId": 7001,
            "ResourceType": 1,
            "TopOrganizationId": 50015917,
            "OrganizationId": 50400374,
            "Updated": 1546845152,
            "Created": 1546845148,
            "Status": 1,
            "VPCId": "uvnet-4xe01o",
            "SubnetId": "subnet-rxrgq3",
            "BusinessId": "business_id-m3uddk"
        }
    ]
}'''

resp2 = '''{
    "Action": "TransformIPv4ToIPv6Response",
    "IpV6": "2003:da8:2004:1000:0a01:0105:0306:7034",
    "Message": "2003:da8:2004:1000:0a01:0105:0306:7034",
    "RetCode": 0
}'''


# input = '{"url":"http://internal.api.ucloud.cn", "resourceId":"uhost-43uhr1", "regionId":"1000003"}'



def main():
    inputs_from_terraform = sys.stdin.readline()
#     inputs_from_terraform = input
    input_json = json.loads(inputs_from_terraform)
    url = input_json['url']
    resourceId = input_json['resourceId']
    regionId = input_json['regionId']
    cmd = 'curl -X POST -s {0} -H \'Content-Type: application/json\' -H \'cache-control: no-cache\' -d \'{{"Action": "IGetResourceInfo","Backend": "UResource", "ResourceId":"{1}", "GenerateType": 0, "RegionId": {2}}}\''.format(url, resourceId, regionId)
    resp = commands.getoutput(cmd)

    uuidJson = json.loads(resp)
    uuid = uuidJson['Infos'][0]['ResourceId']
    cmd = 'curl -X POST -s {0} -H \'Content-Type: application/json\' -H \'cache-control: no-cache\' -d \'{{"Action":"ITransformIPv4ToIPv6ByHostId", "ObjectId":"{1}", "RegionId":"{2}", "Backend":"UVPCFEGO"}}\''.format(url, uuid, regionId)
    resp = commands.getoutput(cmd)
    ipv6Json = json.loads(resp)
    ip = ipv6Json['IpV6']
    print('{{"ip":"{0}"}}'.format(ip))


if __name__ == '__main__':
    main()