wget -q -O gpg.key https://rpm.grafana.com/gpg.key

wget -q -O - https://apt.grafana.com/gpg.key

sudo rpm --import gpg.key

cat > /etc/yum.repos.d/grafana.repo << EOF
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
exclude=*beta*
EOF

dnf install grafana -y

systemctl enable grafana-server
systemctl start grafana-server
systemctl status grafana-server