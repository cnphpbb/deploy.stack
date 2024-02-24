#!/usr/bin/env bash

function pull_rsync_all() {
    cd /data/databanks/seal-ms/sealms-ui
    git pull origin develop
    cd /data/databanks/seal-ms/sealms
    git pull origin develop
    sleep 1
    rsync -auvz --exclude=".git/" /data/databanks/seal-ms/ /data/databanks/build-sync/seal-ms/
}

function ui_rsync() {
    rsync -auvz /data/databanks/build-sync/seal-ms/sealms-ui/dist/ /data/www-root/seal-ms/sealms-ui/
}

function go_rsync() {
    rsync -auvz /data/databanks/build-sync/seal-ms/sealms/release/ /data/www-root/seal-ms/sealms/release/
}

function ui_build() {
  cmd="cd /data/seal-ms/sealms-ui; yarn build:prod"
  bash -c "docker exec -i build-node sh -c '${cmd}'"
}

function go_build() {
  cmd="/data/seal-ms/sealms/build.sh linux"
  bash -c "docker exec -i build-golang sh -c '${cmd}'"
}

function go_restart() {
  bash -c "docker restart sealms_sealms_1"
}

function help() {
    echo "-h  --help           Help "
    echo " "
    echo "0|prall                git -> rsync all project src "
    echo " "
    echo "a1|api-build            only build Api "
    echo "a2|api-rsync            only rsync Api "
    echo "a3|api-restart          only restart docker Container "
    echo "aa|api-all             only build -> rsync -> restart Api "
    echo " "
    echo "ub|ui-build            only build frontend "
    echo "ur|ui-rsync            only build frontend ToRsync"
    echo "ua|ui-all            only build frontend ToRsync"
    echo " "
    echo "all                  git -> rsync -> build -> ToRsync -> restart  all project "
    echo " "
}

case $1 in
  ""|"-h"|"--help")
    help;;
  "0"|"prall")
    pull_rsync_all;;
  "a1"|"api-build")
    pull_rsync_all
    go_build
    ;;
  "a2"|"api-rsync")
    go_rsync
    ;;
  "a3"|"api-restart")
    go_restart
    ;;
  "aa"|"api-all")
    pull_rsync_all
    sleep 1
    go_build
    sleep 1
    go_rsync
    go_restart
    ;;
  "ub"|"ui-build")
    pull_rsync_all
    ui_build
    ;;
  "ur"|"ui-rsync")
    ui_rsync
    ;;
  "ua"|"ui-all")
    pull_rsync_all
    sleep 1
    ui_build
    sleep 1
    ui_rsync
    ;;
  "all")
    pull_rsync_all
    go_build
    go_rsync
    go_restart
    ui_build
    ui_rsync
    ;;
esac