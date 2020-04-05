#!/usr/bin/bash

USERID=$(id -u)
LOG=/tmp/apacheSetup.log
R="\e[31m"
N="\e[0m"
G="\e[32m"
Y="\e[33m"

#SOURCE URL'S
HTTPD_URL=https://downloads.apache.org//httpd/httpd-2.4.43.tar.gz
APR_URL=https://downloads.apache.org//apr/apr-1.7.0.tar.gz
APR_UTIL_URL=https://downloads.apache.org//apr/apr-util-1.6.1.tar.gz
EXPAT_URL=https://github.com/libexpat/libexpat/releases/download/R_2_2_7/expat-2.2.7.tar.gz

HTTP_DIR=$(echo $HTTPD_URL | awk -F / {'print $NF'} | sed 's/.tar.gz//g')
APR_UTIL_DIR=$(echo $APR_UTIL_URL | awk -F / {'print $NF'} | sed 's/.tar.gz//g')
APR_DIR=$(echo $APR_URL | awk -F / {'print $NF'} | sed 's/.tar.gz//g')
EXPAT_DIR=$(echo $EXPAT_URL | awk -F / {'print $NF'} | sed 's/.tar.gz//g')

HTTPD_ROOT=/etc/apache2

verify()
{
    if [ $1 != 0 ] ; then
        echo -e "$2... $R FAILURE $N"
        exit 1
    else
        echo -e "$2... $G SUCCESS $N"
    fi
}

SKIP(){
    echo -e "$Y $1 ... SKIPPING $N"
}

if [ $USERID != 0 ]; then
    echo -e "$R You have to be root user to run this script $N"
    exit  1
fi

yum install wget gcc pcre-devel openssl-devel -y &>$LOG
verify $? "necessary packages installation"

#check if apache user & group already created
APACHE_USER_ID=$(id apache -u)

if [ $APACHE_USER_ID > 0 ] ; then
    SKIP "apache user already exists"
else
    #create apache service user
    useradd -r apache
    verify $? "apache user&group creation"
fi

cd ~
if [ -d sources ]; then
    SKIP "sources directory already exists"
else
    mkdir sources
fi
cd sources

#Download and extract HTTPD
wget -qO- $HTTPD_URL | tar -xz
verify $? "Downloading HTTPD"
#Download and extract APR
wget -qO- $APR_URL | tar -xz
verify $? "Downloading APR"
#Download and extract APR-UTIL
wget -qO- $APR_UTIL_URL | tar -xz
verify $? "Downloading APR-UTIL"

echo "APR_DIR: $APR_DIR"
echo "APR_UTIL_DIR: $APR_UTIL_DIR"
echo "HTTP_DIR: $HTTP_DIR"

set -o xtrace
#copy apr, apr-util to srclib directory
cp -r $APR_DIR $HTTP_DIR/srclib/apr
verify $? "copied apr-util to srclib"
cp -r $APR_UTIL_DIR $HTTP_DIR/srclib/apr-util
verify $? "copied apr to srclib"

#download the expat library and install, this is for XML library
wget -qO- $EXPAT_URL | tar -xz
verify $? "Downloading expat"

cd $EXPAT_DIR
#run configure and isntall script
./configure &>$LOG && make &>$LOG && make install &>$LOG
verify $? "installing expat"

#run configurie, make and install of httpd
cd ../$HTTP_DIR
./configure --prefix=$HTTPD_ROOT --enable-ssl --enable-so --with-included-apr --with-mpm=event &> $LOG 
verify $? "Configuring Apache2"
make &> $LOG
verify $? "Building Apache2"
make install &> $LOG
verify $? "Installing Apache2"

#chown -R apache:apache $HTTPD_ROOT
#verify $? "changing ownerhsip of $HTTPD_ROOT to apache"

cd $HTTPD_ROOT/bin
sh apachectl -k graceful
verify $? "apache started"




