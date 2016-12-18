#!/bin/bash
#
# 21-Oct-2016 : ksrirama - Added support for wildfly
#
#
#
###########################################################
#
### Usage function
#
usage()
{

        echo "
Usage :
./3_configure_DMS_jar.sh [-help] [-pfsHome=<PFS_HOME location>] [-mongoHost=<MongoDB Hostname>] [-mongoPort=<MongoDB Port>] [-mongoDbName=<MongoDB Repository Name>] [-mongoUser=<MongoDB Username>] [-mongoUserPass=<MongoDB User password>] [-silent] [-propFile=<properties file>] [-wildfly=<true/false>]

Where:
pfsHome          : PFS Install location -- Default location :  $HOME/PFS/TEST
wildfly          : Is DMS running in Wildfly ? (true/false)  -- Default :  true
mongoHost        : Hostname where MongoDB is installed - Default : NONE
mongoPort        : Port number where MongoDB is running on - Default : 27017
mongoDbName      : MongoDB Database name used for DMS repository - Default : dmsrepo
mongoUser        : MongoDB Username for DMS repository - Default : dmsuser
mongoUserPass    : MongbDB Username Password (in AES encryption value)- Default : admin
mongoUserPassEnc : Encryption value of MongoDB Username Password  - Default : NONE
propFile         : Properties file containing key-value pairs for all the environment details. Command line argument overrides values in properties file.
silent           : Do not prompt for inputs, use default values

Eg:
./3_configure_DMS_jar.sh

./3_configure_DMS_jar.sh -pfsHome=/path/to/PFS/79212

./3_configure_DMS_jar.sh -pfsHome=/home/dh/PFS/TEST -mongoHost=192.168.4.88  -mongoPort=27017 -mongoDbName=dmsrepo -mongoUser=dmsuser -mongoUserPass=admin

./3_configure_DMS_jar.sh -pfsHome=/home/dh/PFS/TEST -mongoHost=192.168.4.88  -mongoPort=27017 -mongoDbName=dmsrepo 

Note:
The script needs to be run in bash shell

"


	
}


#
### Parse the command line arguments
#
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=${1#${PARAM}=}
#    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | -help)
            usage
            exit
            ;;
        -propFile)
            propFile=$VALUE
            ;;
        -wildfly)
            wildfly=$VALUE
            ;;
        -mongoHost)
            mongoHost=$VALUE
            ;;
        -mongoPort)
            mongoPort=$VALUE
            ;;
        -mongoDbName)
            mongoDbName=$VALUE
            ;;
        -silent)
            silent="true"
            ;;
        -mongoUser)
            mongoUser=$VALUE
            ;;
        -mongoUserPassEnc)
            mongoUserPassEnc=$VALUE
            ;;
        -mongoUserPass)
            mongoUserPass=$VALUE
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

echo
echo
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " 		Configuration scrpt for DMS "
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo
#
### BEGIN
#
date=`date`
echo 
echo "Script start time : $date"
echo



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

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$PATH"

echo
echo
echo "Using PATH : $PATH"
echo
echo


### If properties file is provided, get the values from there

if [ "x${propFile}" != "x" ] && [ -r $propFile ]
then

        echo
        echo "Properties file is provided, let us read the environment details from there."
        echo

        if [ "x${pfsHome}" == "x" ]
        then
                getKeyValue "${propFile}" "pfs.home"
                pfsHome=$value
        fi

        if [ "x${mongoHost}" == "x" ]
        then
                getKeyValue "${propFile}" "mongodb.hostname"
                mongoHost=$value
        fi

        if [ "x${mongoPort}" == "x" ]
        then
                getKeyValue "${propFile}" "mongodb.port" "27017"
                mongoPort=$value
        fi


        if [ "x${mongoDbName}" == "x" ]
        then
                getKeyValue "${propFile}" "mongodb.name" "dmsrepo"
                mongoDbName=$value
        fi


        if [ "x${mongoUser}" == "x" ]
        then
                getKeyValue "${propFile}" "mongodb.username" "dmsuser"
                mongoUser=$value
        fi


        if [ "x${mongoUserPass}" == "x" ]
        then
                getKeyValue "${propFile}" "mongodb.password" "admin"
                mongoUserPass=$value
        fi

        if [ "x${mongoUserPassEnc}" == "x" ]
        then
                getKeyValue "${propFile}" "mongodb.password.encrypted" "x"
                mongoUserPassEnc=$value
        fi


        if [ "x${wildfly}" == "x" ]
        then
                getKeyValue "${propFile}" "dms.wildfly" "true"
                wildfly=$value
        fi



### Enable silent as properties file is passed
	silent="true"

fi

if [ "x${silent}" = "x" ]
then
        silent="false"
fi






### Let us try to prompt the user for PFS_HOME, OMS DB and OMS DB Hostname in case not provided as a parameter

if [ "x${pfsHome}" == "x" ] && [ "$silent" == "false" ]
then
	echo "Enter the PFS_HOME Location [Press enter to use the default location $HOME/PFS/TEST]:"
	read pfsHome
fi


### Use the default values in case still not provided
if [ "x${pfsHome}" == "x" ]
then
	pfsHome="$HOME/PFS/TEST"
	echo "INFO: PFS_HOME location is not provided, using the default location $pfsHome"
else
	echo "Using PFS_HOME location provided : $pfsHome"
fi


#
### DMS configuration file
#

echo
echo "Starting DMS configurations."
echo

if [ "x${mongoHost}" == "x" ] && [ "$silent" == "false" ]
then
	echo "Enter the Mongo DB Hostname : "
	read mongoHost
fi

if [ "x${mongoPort}" == "x" ] && [ "$silent" == "false" ]
then
	echo "Enter the Mongo DB Port [Default : 27017] :"
	read mongoPort
fi


if [ "x${mongoDbName}" == "x" ] && [ "$silent" == "false" ]
then
	echo "Enter the Mongo DB Name [Default : dmsrepo ]:"
	read mongoDbName
fi

if [ "x${mongoUser}" == "x" ] && [ "$silent" == "false" ]
then
	echo "Enter the Mongo DB Username [Default : dmsuser ]:"
	read mongoUser
fi

if [ "x${mongoUserPass}" == "x" ] && [ "$silent" == "false" ]
then
	echo "Enter the Mongo DB Username Password [Default : admin ]:"
	read mongoUserPass
fi



### Use the default values in case still not provided
if [ "x${mongoPort}" == "x" ]
then
	mongoPort="27017"
	echo "INFO: Mongo DB Port number is not provided, using the default port number $mongoPort"
else
	echo "Using Mongo DB Port number provided - $mongoPort"
fi

if [ "x${mongoDbName}" == "x" ]
then
	mongoDbName="dmsrepo"
	echo "INFO: Mongo DB name is not provided, using the default DB Name $mongoDbName"
else
	echo "Using Mongo DB name provided - $mongoDbName"
fi

if [ "x${mongoUser}" == "x" ]
then
	mongoUser="dmsuser"
	echo "INFO: Mongo DB username is not provided, using the default username $mongoUser"
else
	echo "Using Mongo DB username provided - $mongoUser"
fi


if [ "x${mongoUserPass}" == "x" ]
then
	mongoUserPass="admin"
	echo "INFO: Mongo DB Username password is not provided, using the default password $mongoUserPass"
else
	echo "Using Mongo DB Username password provided - $mongoUserPass"
fi


### Use the encrypted values for Password

#if [ "$mongoUserPass" == "admin" ]
#then
#	mongoUserPassEnc="1Z+7Cuvg/cqZE3peF2LnIQ=="
#fi


### Exit the script if mongoHost is NOT PASSED in -silent mode
if [ "x${mongoHost}" == "x" ]
then
        echo
        echo "ERROR : MongoDB Hostname is a mandatory requirement for the script. No default value is available"
        echo
        exit 1
fi

#
### Encrypt the password using AES
#

aesEncryptionJar="${scriptDir}/files/AesEncryption.jar"

if [ ! -r $aesEncryptionJar ]
then
	echo
	echo "ERROR: Unable to read AES encryption JAR file at $aesEncryptionJar"
	echo
	exit 1
fi

javaExe="${pfsHome}/jdk1.6.0_17/bin/java"

if [ ! -x $javaExe ]
then
	echo
	echo "ERROR: Unable to find java executable $javaExe"
	echo
	exit 1
fi


	if [ "x${mongoUserPassEnc}" == "xx" ]
	then
		mongoUserPassEnc=`${javaExe} -jar ${aesEncryptionJar} E $mongoUserPass`
	fi

	echo
	echo "MongoDB user password encrypted value : $mongoUserPassEnc"
	echo

	if [ "x${mongoUserPassEnc}" == "xx" ]
	then
		echo
		echo "ERROR: Unable to determine Encrypted value for Mongo DB user password. Use -mongoUserPassEnc option to pass the value."
		echo
		exit 1
	fi


###############################################################################################################

echo
echo
echo "Updating dms-configiration.properties file....."
echo

dmsConfFile="${pfsHome}/jboss-5.1.0.GA/server/default/conf/dms-configuration.properties"
dmsConfFileUpdated="/tmp/dms-configuration.properties"

runCmd "rm -f $dmsConfFileUpdated"

if [ "$wildfly" == "true" ]
then
	restAPI="true" 
else
	restAPI="false"
fi

mongoConnStr="mongodb://${mongoUser}:${mongoUserPass}@${mongoHost}:${mongoPort}/${mongoDbName}?ssl=true"

echo "
# DMS Configuration file

# DMS AES encryption related properties
keystore.filename=sso-aes256-keystore.jck
keystore.password=dhi\$123
alias.name=ssoaes256
key.password=dhi\$123
initial.iv=1111100010011111

RestEnabled=${restAPI}

mongo.connection.uri=$mongoConnStr
mongohost=$mongoHost
mongoport=$mongoPort
mongodbname=$mongoDbName
encryptPassword=$mongoUserPassEnc
userName=$mongoUser
">$dmsConfFileUpdated

echo
runCmd "cp $dmsConfFileUpdated $dmsConfFile"
echo


runCmd "rm -f $dmsConfFileUpdated"



#
### END
#
date=`date`
echo
echo "Script end time : $date"
echo



### Now exit gracefully
exit 0
