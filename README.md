Git auto-updating container
---------------------------

This image:
 - takes a `GIT_URL`, that it clones and expose as a volume (`/git`)
 - polls from the git remote periodically

Arguments:
 - `GIT_URL`: provided as this to git clone
 - `POLLING_FREQ`: polling frequency as given to cron, something like "*/5 * * * *", default to 5 minutes
 - `SSH_KEY`: can be used to provide an SSH key to authenticate against remote repository
 - `VOLUME_PATH`: if you're not happy with the default volume `/git`

Warning:
 - `SSH_KEY` expect as base64'd string
 - In case URL is ssh (ssh:// or git@), the image will automatically accept the remote key.

For instance you can deploy this as a systemd unit to serve an always up-to-date repository to other services.

Sample usages:

 - HTTP repository:
```
docker run \
            --rm \
            --name legato-docs
            -e GIT_URL=https://github.com/legatoproject/legato-docs.git \
            corfr/git-autoupdate
```

 - SSH repository:
```
docker run \
            --rm \
            --name legato-docs
            -e GIT_URL=git@github.com:legatoproject/legato-docs.git \
            -e SSH_KEY="$(cat ~/.ssh/id_rsa | base64)" \
            corfr/git-autoupdate
```

 - Expose repository as another name:
```
docker run \
            --rm \
            --name legato-docs
            -e GIT_URL=https://github.com/legatoproject/legato-docs.git \
            -e VOLUME_PATH=/legato-docs \
            -v /legato-docs \
            corfr/git-autoupdate
```

