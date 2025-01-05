#!/usr/bin/env sh

set -e

if [ -z "${DB_PATH}" ]; then
    export DB_PATH=/var/lib/fruit-jokes
fi

if [ ! -d "${DB_PATH}" ]; then
    echo "INFO: Creating database directory ${DB_PATH}..."
    mkdir -p "${DB_PATH}"
fi

echo "INFO: Attempting to restore database if missing..."
litestream restore -if-db-not-exists -if-replica-exists ${DB_PATH}/fruit-jokes.db

cd ${DB_PATH}

echo "INFO: Starting application using Litestream..."
exec litestream replicate -exec 'fruit-jokes'
