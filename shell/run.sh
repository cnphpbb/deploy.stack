#!/usr/bin/env bash
#报错:
# hint: You have divergent branches and need to specify how to reconcile them. hint: You can do so by running one of the following commands sometime before hint: your next pull: hint: hint: git config pull.rebase false # merge hint: git config pull.rebase true # rebase hint: git config pull.ff only # fast-forward only hint: hint: You can replace "git config" with "git config --global" to set a default hint: preference for all repositories. You can also pass --rebase, --no-rebase, hint: or --ff-only on the command line to override the configured default per hint: invocation. fatal: Need to specify how to reconcile divergent branches.

#解决:
# git config pull.rebase false
updatesh() {
    local dir=$1
    echo "update ${dir}"
    cd ${dir} && git fetch --all && git reset --hard origin/main && git pull
}

# 调用函数
updatesh "/data/deploy.stack"


