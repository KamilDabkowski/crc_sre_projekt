echo "create prometheus user"
 
useradd -m -s /bin/bash prometheus
 
echo "download packages"
 
wget -P /home/prometheus/ https://github.com/prometheus/prometheus/releases/download/v2.45.3/prometheus-2.45.3.linux-amd64.tar.gz
wget -P /home/prometheus/ https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
wget -P /home/prometheus/ https://github.com/prometheus-community/postgres_exporter/releases/download/v0.9.0/postgres_exporter-0.9.0.linux-amd64.tar.gz
wget -P /home/prometheus/ https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz
 
echo "unpack archives"
 
tar -xf /home/prometheus/prometheus-2.45.3.linux-amd64.tar.gz -C /home/prometheus
tar -xf /home/prometheus/node_exporter-1.7.0.linux-amd64.tar.gz -C /home/prometheus
tar -xf /home/prometheus/postgres_exporter-*.linux-amd64.tar.gz -C /home/prometheus
tar -xf /home/prometheus/alertmanager-*.linux-amd64.tar.gz -C /home/prometheus
 
echo "change names to more user friendly"
 
mv /home/prometheus/prometheus-2.45.3.linux-amd64 /home/prometheus/prometheus
mv /home/prometheus/node_exporter-1.7.0.linux-amd64 /home/prometheus/node_exporter
mv /home/prometheus/postgres_exporter-*.linux-amd64 /home/prometheus/postgres_exporter
mv /home/prometheus/alertmanager-*.linux-amd64 /home/prometheus/alertmanager

echo "create prometheus data dir"
 
mkdir -p /home/prometheus/prometheus/data
mkdir -p /home/prometheus/alertmanager/data

mv /tmp/crc/centos_rules.yml /home/prometheus/prometheus/centos_rules.yml
mv -f /tmp/crc/prometheus.yml /home/prometheus/prometheus/prometheus.yml
mv -f /tmp/crc/alertmanager.yml /home/prometheus/alertmanager/alertmanager.yml

echo "correct permissoins"
 
chown -R prometheus:prometheus /home/prometheus/
 
echo "create prometheus service file"
 
cat > /etc/systemd/system/prometheus.service << EOF
[Unit]
Description=Prometheus Server
After=network-online.target
[Service]
User=prometheus
Restart=on-failure
ExecStart=/home/prometheus/prometheus/prometheus --config.file=/home/prometheus/prometheus/prometheus.yml --storage.tsdb.path=/home/prometheus/prometheus/data
[Install]
WantedBy=multi-user.target
EOF
 
echo "create node_exporter service file"
 
cat > /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
ExecStart=/home/prometheus/node_exporter/node_exporter
[Install]
WantedBy=default.target
EOF

echo "create alertmanager service file"

cat > /etc/systemd/system/alertmanager.service << EOF
[Unit]
Description=alertmanager
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
ExecStart=/home/prometheus/alertmanager/alertmanager --config.file=/home/prometheus/alertmanager/alertmanager.yml --storage.path="/home/prometheus/alertmanager/data"
[Install]
WantedBy=default.target
EOF

echo "create postgres_exporter data file"

cat > /home/prometheus/postgres_exporter/postgres_exporter.env << EOF
DATA_SOURCE_NAME="postgresql://postgres:postgres@localhost:5432/applications?sslmode=disable"
EOF

echo "create postgres_exporter service file"

cat > /etc/systemd/system/postgres_exporter.service << EOF
[Unit]
Description=postgres exporter
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
WorkingDirectory=/home/prometheus/postgres_exporter
ExecStart=/home/prometheus/postgres_exporter/postgres_exporter --web.listen-address=:9187 --web.telemetry-path=/metrics
EnvironmentFile=/home/prometheus/postgres_exporter/postgres_exporter.env
Restart=no
[Install]
WantedBy=default.target
EOF
 
echo "enable services"
 
systemctl enable prometheus.service node_exporter.service postgres_exporter.service
 
echo "start services and check status"
 
systemctl start prometheus.service node_exporter.service alertmanager.service postgres_exporter.service
systemctl status prometheus.service node_exporter.service alertmanager.service postgres_exporter.service