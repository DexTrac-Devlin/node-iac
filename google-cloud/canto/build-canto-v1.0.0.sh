#!/bin/bash

# ================================================= #
# This script will deploy a Fantom mainnet RPC node #
# ================================================= #

# ================================================= #
#                   Variables                       #
# ================================================= #
# Please update the following variables as needed.
USERNAME=devlin


# ================================================= #
#                Deploy Canto Node                  #
# ================================================= #
# Install go
mkdir -p ~/stuff/packages
wget https://go.dev/dl/go1.20.4.linux-amd64.tar.gz -P ~/stuff/packages
cd ~/stuff/packages
tar xvf go1.20.4.linux-amd64.tar.gz
sudo chown -R root:root ./go
sudo mv go /usr/local/
cd
cat >> ~/.profile << EOL
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
EOL

source ~/.profile

# Clone Canto repo, compile binaries, and move to path
cd ~/
git clone https://github.com/Canto-Network/Canto.git
cd ~/Canto
git checkout v1.0.0
make
sudo cp ~/Canto/build/cantod /usr/bin/
cd

# Initialize canto
cd ~/Canto
./build/cantod init LayerZero --chain-id canto_7700-1
cd ~/.cantod/config
rm ~/.cantod/config/genesis.json
wget https://github.com/Canto-Network/Canto/raw/genesis/Networks/Mainnet/genesis.json
# Update config
sed -i 's/seeds = ""/seeds = "ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@seeds.polkachu.com:15556"/g' ~/.cantod/config/config.toml
sed -i 's/minimum-gas-prices = "0acanto"/minimum-gas-prices = "0.0001acanto"/g' ~.cantod/config/app.toml
sed -i 's/pruning = "default"/pruning = "nothing"/g' ~.cantod/config/app.toml
cd
cp -r ~/.cantod /mnt/data/canto-data/

# Create & start cantod.service
sudo touch /etc/systemd/system/cantod.service
sudo cat > /etc/systemd/system/cantod.service << EOL
[Unit]
Description=Canto Node
After=network.target

[Service]
Type=simple
User=$USERNAME
WorkingDirectory=/mnt/data/canto-data/.cantod/
ExecStart=/home/$USERNAME/go/bin/cantod start --trace --log_level info --json-rpc.api eth,txpool,personal,net,debug,web3 --api.enable
Restart=on-failure
StartLimitInterval=0
RestartSec=3
LimitNOFILE=65535
LimitMEMLOCK=209715200

[Install]
WantedBy=multi-user.target

EOL

# start service
sudo systemctl daemon-reload
sudo systemctl enable cantod.service
sudo systemctl start cantod.service

# ================================================= #
#     Notes for upgrading to next binary            #
# ================================================= #
# Once the node syncs to tallest block for this
# binary, the service will start to fail.
# you must run the bash script for that
# next release or upgrade the node manually.
#
# The releases and their associated bash script are as follows:
#  cantod-v1.0.0 -- build-canto.sh
#  cantod-v2.0.0 -- build-canto-v2.0.0.sh
#  cantod-v3.0.0 -- build-canto-v3.0.0.sh
#  cantod-v4.0.0 -- build-canto-v4.0.0.sh
#  cantod-v5.0.0 -- build-canto-v5.0.0.sh
