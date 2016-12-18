#!/bin/bash

####################################################################################
dirName=`dirname $0`

PWD=`pwd`

### For absolute PATH
echo "$dirName" | grep ^/ > /dev/null

if  [ $? -eq 0 ]
then
        scriptDir=$dirName
elif [ $dirName == "." ]
then
        scriptDir="$PWD"
else
        scriptDir=`cd ${PWD}/${dirName}; pwd`
fi


if [ ! -f ${scriptDir}/lib/commonFunctions.lib ]
then
        echo
        echo "ERROR : Common functions file commonFunctions.lib is NOT FOUND."
        echo
        exit 1
fi

. ${scriptDir}/lib/commonFunctions.lib

####################################################################################

currUser=`whoami`
if [ "${currUser}" == "root" ]
then
        sudo=""
else
        sudo="sudo"
fi





runCmd "$sudo rm -rf /etc/ssl/mongodb-cert.crt_*"

runCmd "$sudo rm -rf /etc/ssl/certificate.der_*"

runCmd "$sudo rm -rf /etc/ssl/mongodb.pem_*"

runCmd "$sudo rm -rf /etc/ssl//etc/ssl/mongodb-cert.key_*"

runCmd "$sudo rm -rf /opt/wildfly-8.2.0.Final_*"

runCmd "rm -rf /home/dh/jdk1.6.0_17_*"

runCmd "rm -rf ${HOME}/jdk1.8.0_72_*"


runCmd "rm -rf ${HOME}/MongoDB_*"
runCmd "rm -rf ${HOME}/mongoDB_*"

runCmd "rm -rf ${HOME}/PFS/TEST_*"

runCmd "rm -rf ${HOME}/identity.jks_*"

