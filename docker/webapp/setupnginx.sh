# Add ngnix configuration.
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


