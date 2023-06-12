#!/bin/bash

# ================================================= #
# This script will deploy a Fantom mainnet RPC node #
# ================================================= #

# ================================================= #
#                   Variables                       #
# ================================================= #
# Please update the following variables as needed.
USER=devlin


# ================================================= #
#                Deploy Canto Node                 #
# ================================================= #
# Install go
mkdir -p /home/$USER/stuff/packages
sudo chown -R $USER:$USER /home/$USER/stuff/packages
wget https://go.dev/dl/go1.20.4.linux-amd64.tar.gz -P /home/$USER/stuff/packages
cd /home/$USER/stuff/packages
sudo chown -R $USER:$USER /home/$USER/stuff/packages
tar xvf go1.20.4.linux-amd64.tar.gz
sudo chown -R root:root ./go
sudo mv go /usr/local/
cd
cat >> /home/$USER/.profile << EOL
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
EOL

source /home/$USER/.profile

# Clone Canto repo, compile binaries, and move to path
cd /mnt/data/canto-data
git clone https://github.com/Canto-Network/Canto.git
sudo chown -R $USER:$USER /mnt/data/canto-data/Canto
cd Canto
git checkout v1.0.0
make install
cp /home/$USER/go/bin/cantod /usr/bin/
cd

# Initialize canto
cd /mnt/data/canto-data/Canto
./build/cantod init LayerZero --chain-id canto_7700-1
cp -r /home/$USER/.cantod /mnt/data/canto-data/
sudo chown -R $USER:$USER /mnt/data/canto-data/.cantod
cd /mnt/data/canto-data/.cantod/config
rm /mnt/data/canto-data/.cantod/config/genesis.json
wget https://github.com/Canto-Network/Canto/raw/genesis/Networks/Mainnet/genesis.json
# Update config
sed -i 's/seeds = ""/seeds = "ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@seeds.polkachu.com:15556"/g' /mnt/data/canto-data/.cantod/config/config.toml
sed -i 's/minimum-gas-prices = "0acanto"/minimum-gas-prices = "0.0001acanto"/g' /mnt/data/canto-data/.cantod/config/app.toml
sed -i 's/pruning = "default"/pruning = "nothing"/g' /mnt/data/canto-data/.cantod/config/app.toml
cd
# Create & start cantod.service
sudo touch /etc/systemd/system/cantod.service
sudo cat > /etc/systemd/system/cantod.service << EOL
[Unit]
Description=Canto Node
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/mnt/data/canto-data/.cantod/
ExecStart=/home/$USER/go/bin/cantod start --trace --log_level info --json-rpc.api eth,txpool,personal,net,debug,web3 --api.enable
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
