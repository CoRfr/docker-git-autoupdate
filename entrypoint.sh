#!/bin/bash -e

if [ -z "$GIT_URL" ]; then
    echo "GIT_URL not provided"
    exit 1
fi

mkdir -p /root/.ssh

SSH_TYPE=${SSH_TYPE:-id_rsa}
POLLING_FREQ=${POLLING_FREQ:-"*/5 * * * *"}

if [ -n "$SSH_KEY" ]; then
    echo "SSH_KEY of type $SSH_TYPE provided"
    echo $SSH_KEY | base64 -d -i > /root/.ssh/$SSH_TYPE
    chmod 700 /root/.ssh/$SSH_TYPE
fi

# Accept key for SSH
if echo $GIT_URL | grep "ssh://"; then
    ssh_host_port=$(echo $GIT_URL | cut -d@ -f2 | cut -d/ -f1)
    ssh_host=$(echo $ssh_host_port | cut -d: -f1)
    ssh_port=$(echo $ssh_host_port | cut -d: -f2)
    if [[ "$ssh_port" == "$ssh_host" ]]; then
        ssh_port=22
    fi
# Accept key for SSH (scp like format)
elif echo $GIT_URL | grep "git@"; then
    ssh_host=$(echo $GIT_URL | cut -d@ -f2 | cut -d: -f1)
    ssh_port=22
fi

if [ -n "$ssh_host" ]; then
    echo "Scanning $ssh_host $ssh_port"
    ssh_keyscan=$(ssh-keyscan -p $ssh_port $ssh_host 2>/dev/null)
    echo $ssh_keyscan > /root/.ssh/known_hosts
fi

git clone $GIT_URL /git

# Make sure the update works
/update.sh

echo "$POLLING_FREQ root /update.sh" > /etc/crontab

rsyslogd
cron
tail -f /var/log/syslog

