#!/bin/bash -e

if [ -z "$GIT_URL" ] && ! [ -e "$VOLUME_PATH/.git" ]; then
    echo "GIT_URL not provided and $VOLUME_PATH is empty"
    exit 1
fi

mkdir -p /root/.ssh

SSH_TYPE=${SSH_TYPE:-id_rsa}
POLLING_FREQ=${POLLING_FREQ:-"*/5 * * * *"}
GIT_BRANCH=${GIT_BRANCH:-master}
GIT_REMOTE=${GIT_REMOTE:-origin}

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

if ! [ -e "$VOLUME_PATH/.git" ]; then
    echo "Cloning $GIT_URL [$GIT_BRANCH] -> $VOLUME_PATH"
    git clone -b $GIT_BRANCH $GIT_URL $VOLUME_PATH
else
    cd $VOLUME_PATH

    if [ -n "$GIT_URL" ]; then
        echo "Setting $GIT_REMOTE @ $GIT_URL"

        if git remote | grep $GIT_REMOTE; then
            git remote set-url $GIT_REMOTE $GIT_URL
        else
            git remote add $GIT_REMOTE $GIT_URL
        fi
    fi

    echo "Fetching $GIT_REMOTE"
    git fetch $GIT_REMOTE
    git reset --hard $GIT_REMOTE/$GIT_BRANCH
fi

# No logrotate
rm /etc/cron.daily/logrotate

echo "export VOLUME_PATH=\"$VOLUME_PATH\"" > /etc/update.env.sh

# Make sure the update works
/update.sh

touch /var/log/update.log
echo "$POLLING_FREQ /update.sh >> /var/log/update.log 2>&1" | crontab -

rsyslogd
cron
CRON_PID=$!
tail -f /var/log/syslog &
tail -f /var/log/update.log &

set +e
if [ -n "$WITH_TCP_TRIGGER" ]; then
    while true; do
        nc -l -p 10000
        echo "TCP triggered" >> /var/log/update.log
        /update.sh >> /var/log/update.log 2>&1
    done
else
    wait $CRON_PID
fi

