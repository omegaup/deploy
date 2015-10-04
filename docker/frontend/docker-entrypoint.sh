#!/bin/bash -e

if [ ! -d /var/lib/omegaup/problems ]; then
	mkdir -p /var/lib/omegaup/problems{,.git}
	chown www-data.www-data /var/lib/omegaup/problems{,.git}
fi

if [ ! -d /var/lib/omegaup/submissions ]; then
	mkhexdirs /var/lib/omegaup/submissions www-data www-data
fi

if [ ! -d /var/lib/omegaup/grade ]; then
	mkhexdirs /var/lib/omegaup/grade omegaup omegaup
fi

exec "$@"
