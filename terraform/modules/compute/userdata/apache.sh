#!/bin/bash

dnf update -y
dnf install -y httpd

systemctl enable httpd
systemctl start httpd

cat <<EOF >/var/www/html/index.html
<h1>AcmeCloud Web Tier</h1>
<p>Apache Auto Scaling Group</p>
EOF