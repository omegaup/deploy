FROM mysql:5.7

MAINTAINER Alan Gonzalez <alanboy@alanboy.net>

ENV MYSQL_USER omegaup
ENV MYSQL_DATABASE omegaup

ADD omegaup.sql /docker-entrypoint-initdb.d/000-omegaup.sql
ADD omegaup-test-data.sql /docker-entrypoint-initdb.d/001-omegaup-test-data.sql
ADD omegaup-countries-and-states.sql /docker-entrypoint-initdb.d/002-omegaup-countries-and-states.sql
