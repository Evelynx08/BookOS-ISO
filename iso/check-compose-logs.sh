#!/usr/bin/env bash
# Lorax may return zero after errors in Anaconda's exit handler or dracut.
set -euo pipefail
logdir="${1:?Usage: check-compose-logs.sh LOGDIR}"
for name in livemedia.log program.log; do
    if [ ! -s "$logdir/$name" ]; then
        echo "Missing compose log: $logdir/$name" >&2
        exit 1
    fi
done
if grep -En 'AnacondaError:|dracut-install: ERROR:|dracut\[E\]:.*FAILED' \
    "$logdir/livemedia.log" "$logdir/program.log"; then
    echo "Compose failed; do not deliver this ISO. Logs: $logdir" >&2
    exit 1
fi
