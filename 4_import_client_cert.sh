#!/bin/bash

#
### Usage Function
#
usage()
{
        echo "
Usage :
./4_import_client_cert.sh [-help] [-clientCert=<client certificate location>] [-javaHome=<JAVA_HOME location>] [-silent] [-aliasName=<key Alias name>] [-propFile=<properties file>]

Where:
clientCert : Client Certificate location to be imported -- Default : NONE
javaHome   : JAVA_HOME Location -- Default : NONE
aliasName  : Key or certificate alias name -- Default : NONE
propFile   : Properties file containing key-value pairs for all the environment details. Command line argument overrides values in properties file.
silent     : Do not prompt for inputs, use default values


Eg:
./4_import_client_cert.sh -pfsHome=/home/dh/PFS/79212

./4_import_client_cert.sh -clientCert=/home/dh/certificate.der 

./4_import_client_cert.sh -clientCert=/home/dh/client_PFS.cer -aliasName=piekey

./4_import_client_cert.sh -clientCert=/home/dh/client_DMS.cer

./4_import_client_cert.sh -clientCert=/home/dh/certificate.der -javaHome=/home/dh/PFS/TEST/jdk1.6.0_17

Note:
The script needs to be run in bash shell

"

} # End of function usage



echo
echo "Script to import the SSL client.cer to <JAVA_HOME>/jre/lib/security/cacerts"
echo


while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=${1#${PARAM}=}
#    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | -help)
            usage
            exit
            ;;
        -silent)
            silent="true"
            ;;
        -javaHome)
            javaHome=$VALUE
            ;;
        -clientCert)
            clientCerFile=$VALUE
            ;;
        -pfsHome)
            pfsHome=$VALUE
            ;;
        *)
            echo 
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

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

checkBash

####################################################################################

if [ "x${silent}" = "x" ]
then
        silent="false"
fi



if [ "x${clientCerFile}" == "x" ]  && [ "$silent" == "false" ]
then
	echo "Enter the client.cer file location : "
	read clientCerFile
	echo
fi


if [ ! -r $clientCerFile ]
then
	echo
	echo "ERROR: Unable to read $clientCerFile"
	echo
	exit 1
fi

if [ "x${javaHome}" == "x" ]  && [ "$silent" == "false" ]
then
	echo "Enter the JAVA_HOME location :"
	read javaHome
	echo
fi

if [ ! -r ${javaHome}/jre/lib/security/cacerts ]
then
	echo "ERROR: Unable to read ${javaHome}/jre/lib/security/cacerts"
	echo
	exit 1

fi

### Get the alias from the client.cer name

echo $clientCerFile | grep "PFS\.cer" >/dev/null
exitCode=$?

if [ $exitCode -eq 0 ]
then
	aliasName="piekey"
	echo "Yeh! Provided client certificate appears to be PFS client.cer"
	echo
fi

echo $clientCerFile | grep "DMS\.cer" > /dev/null
exitCode=$?
if [ $exitCode -eq 0 ]
then
	echo "Yeh! Provided client certificate appears to be DMS client.cer"
	echo
	aliasName="dms"
fi


echo $clientCerFile | grep "certificate\.der" > /dev/null
exitCode=$?
if [ $exitCode -eq 0 ]
then
	echo "Yeh! Provided client certificate appears to be MongoDB certificate.der"
	echo
	aliasName="mongodbkey"
fi


### Prompt the user for the alias name if still unable to find
if [ "x${aliasName}" == "x" ]  && [ "$silent" == "false" ]
then
	echo
	echo "Unable to get the alias name from the certificate name. Please enter the alias name : "
	read aliasName
fi


if [ "x${aliasName}" == "x" ]
then
	echo
	echo "ERROR: Unable to get the alias name from the file name."
	echo
	exit 1;
fi



# Now try to import 

cmd="${javaHome}/bin/keytool -v -noprompt -import -trustcacerts -alias $aliasName -file ${clientCerFile} -keystore ${javaHome}/jre/lib/security/cacerts -storepass changeit"

runCmd "$cmd"

exitCode=$?
echo



