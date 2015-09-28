#!/bin/bash

echo Setting up OmegaUp DB
mysql -hdb --protocol=TCP --port=3306 -uroot -p$MYSQL_ROOT_PASSWORD -e " SET GLOBAL time_zone = '+00:00'; "
mysql -hdb --protocol=TCP --port=3306 -uroot -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE $MYSQL_DB_NAME;" 
mysql -hdb --protocol=TCP --port=3306 -uroot -p$MYSQL_ROOT_PASSWORD $MYSQL_DB_NAME < $OMEGAUP_ROOT/frontend/private/bd.sql

mysql -hdb --protocol=TCP --port=3306 -uroot -p$MYSQL_ROOT_PASSWORD -e 'INSERT INTO Users(username, name, password, verified) VALUES("omegaup", "omegaUp admin", "$2a$08$tyE7x/yxOZ1ltM7YAuFZ8OK/56c9Fsr/XDqgPe22IkOORY2kAAg2a", 1), ("user", "omegaUp user", "$2a$08$wxJh5voFPGuP8fUEthTSvutdb1OaWOa8ZCFQOuU/ZxcsOuHGw0Cqy", 1);'
mysql -hdb --protocol=TCP --port=3306 -uroot -p$MYSQL_ROOT_PASSWORD -e 'INSERT INTO Emails (email, user_id) VALUES("admin@omegaup.com", 1), ("user@omegaup.com", 2);'
mysql -hdb --protocol=TCP --port=3306 -uroot -p$MYSQL_ROOT_PASSWORD -e 'UPDATE Users SET main_email_id=user_id;'
mysql -hdb --protocol=TCP --port=3306 -uroot -p$MYSQL_ROOT_PASSWORD -e 'INSERT INTO User_Roles VALUES(1, 1, 0);'
mysql -hdb --protocol=TCP --port=3306 -uroot -p$MYSQL_ROOT_PASSWORD < $OMEGAUP_ROOT/frontend/private/countries_and_states.sql

echo "Installing States and Countries"

#echo "Installing test db"
#RUN mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE \`$MYSQL_DB_NAME-test\`;" 
#RUN mysql -uroot -p$MYSQL_ROOT_PASSWORD $MYSQL_DB_NAME-test < $OMEGAUP_ROOT/frontend/private/bd.sql
#RUN mysql -uroot -p$MYSQL_ROOT_PASSWORD $MYSQL_DB_NAME-test < $OMEGAUP_ROOT/frontend/private/countries_and_states.sql

