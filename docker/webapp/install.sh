
#-----------------------------------------------------------------------------
#       This is the old OmegaUp installation script. It's onlye here
#       for reference, and it's not currently being used.
#-----------------------------------------------------------------------------

#!/bin/bash
set -evx

# Configuration.
OMEGAUP_ROOT=/opt/omegaup
OMEGAUP_BRANCH=
WWW_ROOT=/var/www/omegaup.com
USER=`whoami`
MYSQL_PASSWORD=omegaup
KEYSTORE_PASSWORD=omegaup
MYSQL_DB_NAME=omegaup
MYSQL_JAR=~/.ivy2/cache/mysql/mysql-connector-java/jars/mysql-connector-java-5.1.29.jar
UBUNTU=`grep Ubuntu /etc/issue | wc -l`
WHEEZY=`grep 'Debian GNU/Linux 7' /etc/issue | wc -l`
SAUCY=`grep 'Ubuntu 13.10' /etc/issue | wc -l`
TRUSTY=`grep 'Ubuntu 14.04' /etc/issue | wc -l`
UTOPIC=`grep 'Ubuntu 14.10' /etc/issue | wc -l`
HOSTNAME=localhost
MINIJAIL_ROOT=/var/lib/minijail

sudo useradd omegaup >/dev/null 2>&1 || echo
sudo useradd www-data >/dev/null 2>&1 || echo

## Install everything needed.
#if [ "$SKIP_INSTALL" != "1" ]; then
#	if [ ! -f /usr/sbin/mysqld ]; then
#		sudo DEBIAN_FRONTEND=noninteractive apt-get install -q -y mysql-server
#		sleep 5
#		mysqladmin -u root password $MYSQL_PASSWORD
#	fi
#fi

## Clone repository.
#if [ ! -d $OMEGAUP_ROOT ]; then
#	sudo mkdir $OMEGAUP_ROOT
#	sudo chown $USER -R $OMEGAUP_ROOT
#	git clone https://github.com/omegaup/omegaup.git $OMEGAUP_ROOT $OMEGAUP_BRANCH
#
#	pushd $OMEGAUP_ROOT
#	# Install githooks
#	stuff/install-githooks.sh
#
#	# Update the submodules
#	git submodule update --init	
#	popd
#fi

# Set up the www root.
if [ ! -d $WWW_ROOT ]; then
	# Link the frontend to nginx.
	sudo mkdir -p `dirname $WWW_ROOT`
	sudo ln -s $OMEGAUP_ROOT/frontend/www $WWW_ROOT
	sudo mkdir $WWW_ROOT/img
	sudo chown www-data.www-data $WWW_ROOT/img
	sudo mkdir $WWW_ROOT/templates
	sudo chown www-data.www-data $WWW_ROOT/templates
fi

# Add ngnix configuration.
if [ "$SKIP_NGINX" != "1" ]; then
	FPM_PORT=127.0.0.1:9000
	cat > default.conf << EOF
server {
listen       80;
server_name  .$HOSTNAME;
client_max_body_size 0;
root   $OMEGAUP_ROOT/frontend/www;

location / {
    index  index.php index.html;
}

include $OMEGAUP_ROOT/frontend/server/nginx.rewrites;

# pass the PHP scripts to FastCGI server listening on $FPM_PORT.
location ~ \.(hh|php)$ {
    fastcgi_keep_conn on;
    fastcgi_pass   $FPM_PORT;
    fastcgi_index  index.php;
    fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
    include        fastcgi_params;
}

# deny access to .htaccess files, if Apache's document root
# concurs with nginx's one
location ~ /\.ht {
    deny  all;
}
}
EOF
	sudo mv default.conf /etc/nginx/conf.d/
	
	if [ -f /etc/nginx/sites-enabled/default ]; then
		sudo mv /etc/nginx/sites-enabled/default /etc/nginx/sites-disabled
	fi

	sudo service php5-fpm stop
	sudo update-rc.d -f php5-fpm remove
	sudo service hhvm restart
	sudo update-rc.d hhvm defaults
	sudo service nginx restart
fi

# Set up runtime directories.
if [ ! -d /var/lib/omegaup ]; then
	sudo mkdir -p /var/lib/omegaup/{compile,grade,input,problems,problems.git,submissions}
	sudo chown www-data.www-data /var/lib/omegaup/{problems,problems.git,submissions}
	sudo chown omegaup.omegaup /var/lib/omegaup/{compile,grade,input}
fi

# check mysql

# Install config.php
if [ ! -f $OMEGAUP_ROOT/frontend/server/config.php ]; then
	pushd $OMEGAUP_ROOT/frontend/server/
	cat > config.php << EOF
<?php
define('OMEGAUP_DB_USER', 'root');
define('OMEGAUP_DB_PASS', '$MYSQL_PASSWORD');
define('OMEGAUP_DB_NAME', '$MYSQL_DB_NAME');
EOF
	popd
fi

# Set up the log.
if [ ! -f /var/log/omegaup/omegaup.log ]; then
	sudo mkdir -p /var/log/omegaup/
	sudo touch /var/log/omegaup/omegaup.log
	sudo chown www-data.www-data /var/log/omegaup/omegaup.log
fi

#chek php config.ini, set values for development

#check writable folders

#check and write config

#install database Omegaup

echo "Setting DB to UTC"
mysql -uroot -p$MYSQL_PASSWORD -e " SET GLOBAL time_zone = '+00:00'; "

if [ ! `mysql -uroot -p$MYSQL_PASSWORD --batch --skip-column-names -e "SHOW DATABASES LIKE '$MYSQL_DB_NAME'" | grep $MYSQL_DB_NAME` ]; then
	echo "Installing DB"
	mysql -uroot -p$MYSQL_PASSWORD -e "CREATE DATABASE $MYSQL_DB_NAME;" 
	mysql -uroot -p$MYSQL_PASSWORD $MYSQL_DB_NAME < $OMEGAUP_ROOT/frontend/private/bd.sql
	# omegaup:omegaup
	# user:user
	mysql -uroot -p$MYSQL_PASSWORD $MYSQL_DB_NAME -e 'INSERT INTO Users(username, name, password, verified) VALUES("omegaup", "omegaUp admin", "$2a$08$tyE7x/yxOZ1ltM7YAuFZ8OK/56c9Fsr/XDqgPe22IkOORY2kAAg2a", 1), ("user", "omegaUp user", "$2a$08$wxJh5voFPGuP8fUEthTSvutdb1OaWOa8ZCFQOuU/ZxcsOuHGw0Cqy", 1);'
	mysql -uroot -p$MYSQL_PASSWORD $MYSQL_DB_NAME -e 'INSERT INTO Emails (email, user_id) VALUES("admin@omegaup.com", 1), ("user@omegaup.com", 2);'
	mysql -uroot -p$MYSQL_PASSWORD $MYSQL_DB_NAME -e 'UPDATE Users SET main_email_id=user_id;'
	mysql -uroot -p$MYSQL_PASSWORD $MYSQL_DB_NAME -e 'INSERT INTO User_Roles VALUES(1, 1, 0);'
	
	echo "Installing States and Countries"
	mysql -uroot -p$MYSQL_PASSWORD $MYSQL_DB_NAME < $OMEGAUP_ROOT/frontend/private/countries_and_states.sql

	echo "Installing test db"
	mysql -uroot -p$MYSQL_PASSWORD -e "CREATE DATABASE \`$MYSQL_DB_NAME-test\`;" 
	mysql -uroot -p$MYSQL_PASSWORD $MYSQL_DB_NAME-test < $OMEGAUP_ROOT/frontend/private/bd.sql
	mysql -uroot -p$MYSQL_PASSWORD $MYSQL_DB_NAME-test < $OMEGAUP_ROOT/frontend/private/countries_and_states.sql
fi

#test curl

#test index with curl

#setup tests
if [ ! -f $OMEGAUP_ROOT/frontend/tests/test_config.php ]; then
	cat > $OMEGAUP_ROOT/frontend/tests/test_config.php << EOF
<?php
define('OMEGAUP_DB_USER', 'root');
define('OMEGAUP_DB_PASS', '$MYSQL_PASSWORD');
define('OMEGAUP_DB_NAME', '$MYSQL_DB_NAME-test');
EOF
fi

if [ ! -f $OMEGAUP_ROOT/frontend/tests/controllers/omegaup.log ]; then
	touch $OMEGAUP_ROOT/frontend/tests/controllers/omegaup.log
fi

if [ ! -d $OMEGAUP_ROOT/frontend/tests/controllers/problems ]; then
	mkdir $OMEGAUP_ROOT/frontend/tests/controllers/problems
fi

if [ ! -d $OMEGAUP_ROOT/frontend/tests/controllers/submissions ]; then
	mkdir $OMEGAUP_ROOT/frontend/tests/controllers/submissions
fi

# Execute tests
if [ "$SKIP_PHPUNIT" != "1" ]; then
	if [ "`grep '\/usr\/share\/php' /etc/hhvm/php.ini | wc -l`" -eq 0 ]; then
		cat | sudo tee /etc/hhvm/php.ini << EOF
; php options
include_path = /usr/share/php:.

; hhvm specific
hhvm.log.level = Warning
hhvm.log.always_log_unhandled_exceptions = true
hhvm.log.runtime_error_reporting_level = 8191
hhvm.mysql.typed_results = false
EOF
	fi
	pushd $OMEGAUP_ROOT/frontend/tests/
	hhvm /usr/bin/phpunit controllers/
	popd
fi

echo SUCCESS
