#!/bin/bash
aws_internal_domain=${$1}
aws_region=eu-central-1
aws_hostname=$(aws ec2 describe-tags --region ${aws_region} --filters "Name=resource-id,Values=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)" --query 'Tags[?Key==`Hostname`].Value' --output text)
aws_ip_adress=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

cat <<EOF > /tmp/ip.json
{
    "Comment": "Add Entry",
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "${aws_hostname}.${aws_internal_domain}.",
                "Type": "A",
                "TTL": 300,
                "ResourceRecords": [
                    {
                        "Value": "${aws_ip_adress}"
                    }
                ]
            }
        }
    ]
}
EOF