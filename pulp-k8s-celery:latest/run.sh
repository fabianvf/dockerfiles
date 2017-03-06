#!/usr/bin/env bash

touch log
socat UNIX-LISTEN:/dev/log,perm=0666,fork PIPE:log,unlink-close=0 &

case $1 in
  worker)
    exec /usr/bin/celery worker \
	  --events --app=pulp.server.async.app \
	  --loglevel=INFO \
	  -c 1 \
      --umask=18 \
	  -n reserved_resource_worker@$HOSTNAME \
	  --logfile=/var/log/pulp/reserved_resource_worker.log
    ;;
  beat)
    exec /usr/bin/celery beat --workdir /var/run/pulp/ -A pulp.server.async.app -l INFO
    ;;
  resource_manager)
    exec /usr/bin/celery worker -c 1 -n resource_manager@$HOSTNAME \
      --events --app=pulp.server.async.app \
      --umask=18 \
      --loglevel=INFO -Q resource_manager \
      --logfile=/var/log/pulp/resource_manager.log
    ;;
  *)
    echo "'$1' is not a supported celery command."
    echo "Use one of the following: worker, beat, resource_manager."
    echo "Exiting"
    exit 1
    ;;
esac
