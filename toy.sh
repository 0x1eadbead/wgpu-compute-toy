#!/usr/bin/bash

cleanup() {
    kill "$child_pid"
    wait "$child_pid"
    exit
}

trap "cleanup" SIGINT SIGTERM

while true; do
    ./toy "$@" &

    child_pid="$!"

    wait "$child_pid"
    echo 'Toy crashed again =(, restarting...'
    sleep 1;
done