sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://pkg.pimalaya.org/pimalaya.asc | sudo tee /etc/apt/keyrings/pimalaya.asc >/dev/null
sudo tee /etc/apt/sources.list.d/pimalaya.sources >/dev/null <<EOF
Types: deb
URIs: https://pkg.pimalaya.org/apt
Suites: stable
Components: main
Signed-By: /etc/apt/keyrings/pimalaya.asc
EOF
sudo apt update
