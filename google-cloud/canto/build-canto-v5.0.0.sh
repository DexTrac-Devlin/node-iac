#!/bin/bash

# ================================================= #
#   This will deploy a Canto mainnet archive node   #
# ================================================= #

# ================================================= #
#                   Variables                       #
# ================================================= #
# Please update the following variables as needed.

# ================================================= #
#              Store old binary                     #
# ================================================= #
mkdir -p ~/stuff/binaries
cp ~/go/bin/cantod stuff/binaries/cantod-v4.0.0

# ================================================= #
#  Stop old service, rm old genesis, build new bin  #
# ================================================= #
sudo systemctl stop cantod.service
cd /mnt/data/canto-data/Canto
sudo rm /usr/bin/cantod
git checkout git checkout v5.0.0
make install
sudo cp ~/go/bin/cantod /usr/bin/
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
