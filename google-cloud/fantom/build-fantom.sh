#!/bin/bash

# ================================================= #
# This script will deploy a Fantom mainnet RPC node #
# ================================================= #

# ================================================= #
#                   Variables                       #
# ================================================= #
# Please update the following variables as needed.

# You can find the necessary snapshots at the below URL:
# https://snapshot1.fantom.network/files/pruned/
SNAPSHOT_URL=https://snapshot1.fantom.network/files/pruned/snapshot-06-Jun-2023-21-38/opera-pruned_06-Jun-2023-21-38.tar.gz
SNAPSHOT_FILE=SNAPSHOT_FILE=$(basename "$SNAPSHOT_URL")

# You can find the necessary genesis files at the below URL:
# https://github.com/Fantom-foundation/lachesis_launch/blob/master/docs/genesis-files.md
GENESIS_URL=https://files.fantom.network/mainnet-171200-no-history.g
GENESIS_FILE=$(basename "$GENESIS_URL")

# ================================================= #
#                Deploy Fantom Node                 #
# ================================================= #

# Install go
wget wget https://go.dev/dl/go1.19.1.linux-amd64.tar.gz -P ~/stuff/packages
cd ~/stuff/packages
tar xvf go1.19.1.linux-amd64.tar.gz
sudo chown -R root:root ./go
sudo mv go /usr/local/
cd
cat > ~/.profile << EOL
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
EOL
source ~/.profile

# Clone Fantom Opera repo, compile binaries, and move to path
cd /mnt/data/fantom-data
git clone https://github.com/Fantom-foundation/go-opera.git
cd go-opera
git checkout release/1.1.2-rc.6
make opera
cp build/opera ~/stuff/binaries/opera-v1.1.2-rc.6
cd

# Download snapshot **you'll need to update the URL path to the most recene snapshot**
#  - You can find the URL here: https://snapshot1.fantom.network/files/pruned/
cd /mnt/data/fantom-data/
aria2c $SNAPSHOT_URL
tar xvf $SNAPSHOT_FILE
cd

# Download genesis file
cd /mnt/data/fantom-data
aria2c $GENESIS_URL
mv $GENESIS_FILE mainnet.g
cd

# Create service / daemon for fantom node
sudo touch /etc/systemd/system/fantom-node.service
sudo cat > /etc/systemd/system/fantom-node.service << EOL
[Unit]
 Description=Fantom Full Node
 After=network.target auditd.service
 Wants=network.target

[Service]
 Type=simple
 User=devlin
 WorkingDirectory=/mnt/data/fantom-data/
 TimeoutStartSec=0
 TimeoutStopSec=120
 ExecStart=/mnt/data/fantom-data/go-opera/build/opera \
 --genesis /mnt/data/fantom-data/mainnet.g \
 --maxpeers 80 \
 --cache 9604 \
 --verbosity 2 \
 --metrics \
 --http \
 --http.addr 0.0.0.0 \
 --http.vhosts '*' \
 --ws \
 --ws.addr 0.0.0.0 \
 --ws.origins 0.0.0.0 \
 --datadir /mnt/data/fantom-data/.opera
 Restart=always
 RestartSec=10s

[Install]
 WantedBy=multi-user.target
 RequiredBy=swarm.service
 Alias=fantom-node.service

EOL

# Enable fantom-node.service
sudo systemctl daemon-reload
sudo systemctl enable fantom-node.service
sudo systemctl start fantom-node.service

# Create basic healthcheck script
touch ~/checkState.sh
cat > ~/checkState.sh << EOL
#!/bin/bash

# blue foreground
blue_fg=$(tput setaf 6)
# reset to default
reset=$(tput sgr0)

# SET VARS
FTM_BLOCK_HEIGHT=$(curl -s -H "Content-Type: application/json" http://localhost:18545 -d '{"jsonrpc": "2.0", "id": 123, "method": "eth_blockNumber"}' | jq -r .result)
FTMSCAN_BLOCK_HEIGHT=$(curl -s -d "action=eth_blockNumber&apikey=<api_key>&module=proxy" -X POST https://api.FtmScan.com/api | jq -r .result)
FTM_CURRENT_BLOCK=$(curl -s -H "Content-Type: application/json" http://localhost:18545 -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":74}' | jq -r .result.currentBlock)
FTM_HIGHEST_BLOCK=$(curl -s -H "Content-Type: application/json" http://localhost:18545 -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":74}' | jq -r .result.highestBlock)
IS_SYNCING=$(curl -s -H "Content-Type: application/json" http://localhost:18545 -d '{"jsonrpc": "2.0", "id": 123, "method": "eth_syncing"}' | jq .)

echo "----------------------"
echo "RPC Node Current Block: $${blue_fg}$$((FTM_CURRENT_BLOCK))$${reset}"
echo "RPC Node Highest Block: $${blue_fg}$$((FTM_HIGHEST_BLOCK))$${reset}"
echo ""
echo "RPC Node block height: $${blue_fg}$$((FTM_BLOCK_HEIGHT))$${reset}"
echo "FTM Scan block height: $${blue_fg}$$((FTMSCAN_BLOCK_HEIGHT))$${reset}"

VAR1=$$(curl -s -H "Content-Type: application/json" http://localhost:18545 -d '{"jsonrpc": "2.0", "id": 123, "method": "eth_syncing"}' | jq .result) VAR2="false"

if [ "$$VAR1" = "$$VAR2" ]; then
  echo "Sync Status:           $${blue_fg}Node is synced.$${reset}"
else
  echo "$${blue_fg}Node is $${yellow_fg}NOT$${blue_fg} synced.$${reset}"
fi
EOL

# make init script executable and run it in the background
sudo chown devlin:devlin /mnt/data/fantom-data/init-fantom.sh
chmod +x /mnt/data/fantom-data/init-fantom.sh
bash /mnt/data/fantom-data/init-fantom.sh &
