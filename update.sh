#!/bin/bash

source /etc/update.env.sh

cd $VOLUME_PATH

# Get latest changes from upstream
git pull

# Make sure that there are no changes applied to that repository
git reset --hard
