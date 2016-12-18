#!/bin/bash
#
# 22-Oct-2016 : ksrirama - bind_ip support for startup command 
#
#
#
#
######################################################################
#
### Usage Function
#
usage()
{
        echo "
Usage :
./2_install_MongoDB.sh [-help] [-mongoDbName=<MongoDB Repository Name>] [-mongoUser=<MongoDB Username>] [-mongoUserPass=<MongoDB User password>] [-useSudo] [-mongoHome=<MongoDB HOME location>] [-mongoDataPath=<MongoDB Data Path>] [-silent] [-sleep=<number of seconds>] [-releaseLocation=<Release bits location>] [-propFile=<path to env.properties>]

Where:
releaseLocation : Release Location -- Default : NONE
mongoHome : MongoDB HOME Location -- Default : ${HOME}/MongoDB
mongoDataPath : MongoDB Data Location -- Default : ${HOME}/MongoDB/data
mongoPort : Port number where MongoDB is running on - Default : 27017
mongoDbName : MongoDB Database name used for DMS repository - Default : dmsrepo
mongoUser : MongoDB Username for DMS repository - Default : dmsuser
mongoUserPass : MongbDB Username Password (in AES encryption value)- Default : admin
pemFile : Use the provided pem file for SSL configuration instead of creating a new pem file - Default : Creates a new pem file
useSudo : Pass this option to use sudo for some commands (eg: writing into /data) where root privilege is required 
sleep : Number of seconds to wait/sleep for MongoDB to start up [Default : 20 seconds]
silent : Do not prompt for inputs, use default values
propFile : Properties file containing key-value pairs for all the environment details. Command line argument overrides values in properties file.


Eg:
./2_install_MongoDB.sh 

./2_install_MongoDB.sh -propFile=/path/to/env.properties

./2_install_MongoDB.sh -releaseLocation=/path/to/Release/79212


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
        -releaseLocation)
            releaseLocation=$VALUE
            ;;
        -mongoHome)
            mongoHome=$VALUE
            ;;
        -mongoDataPath)
            mongoDataPath=$VALUE
            ;;
        -sleep)
            sleepTime=$VALUE
            ;;
        -silent)
            silent="true"
            ;;
        -useSudo)
            useSudo="true"
            ;;
        -skipInstall)
            skipInstall="true"
            ;;
        -mongoPort)
            mongoPort=$VALUE
            ;;
        -mongoDbName)
            mongoDbName=$VALUE
            ;;
        -mongoUser)
            mongoUser=$VALUE
            ;;
        -mongoUserPass)
            mongoUserPass=$VALUE
            ;;
        -pemFile)
            pemFile=$VALUE
            ;;
        -pfsHome)
            pfsHome=$VALUE
            ;;
        -omsDB | -omsDb)
            omsDb=$VALUE
            ;;
        -omsDbHost)
            omsDbHost=$VALUE
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
echo "++++++++++++++++++++++++++++++++++++++++++++++++"
echo " 		Mongo DB Installation Script"
echo "++++++++++++++++++++++++++++++++++++++++++++++++"
echo
#
### BEGIN
#
date=`date`
echo 
echo "Script start time : $date"
echo


#####################################################################################
#
# Common Functions
#
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

if [ "x${propFile}" != "x" ] && [ -r $propFile ]
then

        echo
        echo "Properties file is provided, let us read the environment details from there."
        echo

        if [ "x${releaseLocation}" == "x" ]
        then
                getKeyValue "${propFile}" "release.bits.loc"
                releaseLocation=$value
        fi

        if [ "x${mongoHome}" == "x" ]
        then
                getKeyValue "${propFile}" "mongodb.home" 
                mongoHome=$value
        fi

        if [ "x${mongoDataPath}" == "x" ]
        then
                getKeyValue "${propFile}" "mongodb.data.path" "${mongoHome}/data"
                mongoDataPath=$value
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


        if [ "x${pemFile}" == "x" ]
        then
                getKeyValue "${propFile}" "mongodb.pem.file" "x"
                pemFile=$value
        fi

        if [ "x${sleep}" == "x" ]
        then
                getKeyValue "${propFile}" "mongodb.startup.sleep" "20"
                sleep=$value
        fi


### It is silent mode if properties file is used
        silent="true"
fi


if [ "x${silent}" = "x" ]
then
        silent="false"
fi


if [ "x${releaseLocation}" == "x" ] && [ "$silent" == "false" ]
then
        echo
        echo
        echo "Enter the Release location :"
        read releaseLocation
        echo
fi

if [ "x${mongoHome}" == "x" ]  && [ "$silent" == "false" ]
then
        echo
        echo "Enter the Mongo DB HOME Location [Default : ${HOME}/MongoDB]:"
        read mongoHome
        echo
fi


if [ "x${mongoDataPath}" == "x" ]  && [ "$silent" == "false" ]
then
        echo
        echo "Enter the Mongo DB Data Location [Default : ${HOME}/MongoDB/data]:"
        read mongoDataPath
        echo
fi


### Use the default values in case still not provided
if [ "x${mongoHome}" == "x" ]
then
        mongoHome="${HOME}/MongoDB"
        echo "INFO: Mongo DB HOME Location is not provided, using the default location $mongoHome"
        echo
else
        echo "Using Mongo DB HOME Location provided - $mongoHome"
        echo
fi



if [ "x${mongoDataPath}" == "x" ]
then
	mongoDataPath="${mongoHome}/data"
        echo "INFO: Mongo DB Data Location is not provided, using the default location $mongoDataPath"
        echo
else
        echo "Using Mongo DB Data Location provided - $mongoDataPath"
        echo
fi



if [ "x${mongoPort}" == "x" ]
then
        mongoPort="27017"
        echo "INFO: Mongo DB Port number is not provided, using the default port $mongoPort"
        echo
else
        echo "Using Mongo DB Port number provided - $mongoPort"
        echo
fi

if [ "x${mongoDbName}" == "x" ]
then
        mongoDbName="dmsrepo"
        echo "INFO: MongoDB Database name is not provided, using the default Database name $mongoDbName"
        echo
else
        echo "Using MongoDB Database name provided - $mongoDbName"
        echo
fi


if [ "x${mongoUser}" == "x" ]
then
        mongoUser="dmsuser"
        echo "INFO: Mongo DB Username is not provided, using the default username $mongoUser"
        echo
else
        echo "Using Mongo DB Username provided - $mongoUser"
        echo
fi

if [ "x${mongoUserPass}" == "x" ]
then
        mongoUserPass="admin"
        echo "INFO: Mongo DB Username password is not provided, using the default password $mongoUserPass"
        echo
else
        echo "Using Mongo DB Username password provided - $mongoUserPass"
        echo
fi

if [ "x${sleepTime}" == "x" ]
then
        sleepTime="20"
fi

	echo
        echo "INFO: Using sleep time of $sleepTime seconds."
        echo


### By default, let us expect the user to have permissions in the directories and optionally provide facility for running as sudo
#currUser=`whoami`
#if [ "${currUser}" == "root" ]
#then
#	sudo=""
#else
#	sudo="sudo"
#fi

### Make sudo as NULL if useSudo is passed - i.e. when the directories have the required write permissions for the current user
if [ "X${useSudo}" == "Xtrue" ]
then
	sudo="sudo"
fi


### Exit the script if releaseLocation is NOT PASSED in -silent mode
if [ "x${releaseLocation}" == "x" ]
then
        echo
        echo "ERROR : Release location is a mandatory requirement for the script. No default value is available"
        echo
        exit 1
fi

printf "Release location : $releaseLocation\n"

#######################################################################################################

echo
echo "Checking if Mongo DB is running ....."
echo
mongodProcess=`ps -ef | grep -v grep | grep mongod | grep -v 2_install_MongoDB\.sh`

echo

if [ "x${mongodProcess}" != "x" ]
then
        echo
        echo "Mongo DB is currently running. Let us try to kill it first."
        echo
        echo "Mongo DB Process : "
        echo $mongodProcess
        echo

        mongodbProcessID=`echo $mongodProcess | awk '{print \$2'}`

        runCmd "kill -9 $mongodbProcessID"
else
        echo
        echo "Mongo DB is NOT running currently."
        echo
fi



mongoZip="${releaseLocation}/MISC/mongodb-linux-x86_64-ubuntu1404-3.2.4.tgz"

if [ ! -r $mongoZip ]
then
	echo
	echo "ERROR : Unable to read $mongoZip";
	echo
	exit 1
fi

### Yeh. Found mongoZip, let us unzip under $HOME/MongoDB


echo
echo "Found $mongoZip, unzipping under ${mongoHome} ....."
echo


backupFile $mongoHome $sudo

runCmd "$sudo mkdir -p $mongoHome"

runCmd "$sudo tar -zxf $mongoZip -C $mongoHome"


runCmd "$sudo mkdir -p ${mongoHome}/mongodb"

runCmd "$sudo cp -R -n ${mongoHome}/mongodb-linux-x86_64-ubuntu1404-3.2.4/ ${mongoHome}/mongodb"

backupFile $mongoDataPath $sudo

runCmd "$sudo mkdir -p ${mongoDataPath}"


runCmd "$sudo  chown -hR ${currUser}:${currUser} ${mongoDataPath}"

echo
echo "Configuring MongoDB with SSL"
echo "============================"
echo


currDir=`pwd`

echo
echo "Generating the Certificate and Key files for MongoDB."
echo

runCmd "mkdir -p ${mongoHome}/ssl"

	mongoDerFile="${mongoHome}/ssl/certificate.der"
	mongoPemFile="${mongoHome}/ssl/mongodb.pem"


### Create the pem file if not provided

if [ "x${pemFile}" == "xx" ]
then
	mongoCrtFile="${mongoHome}/ssl/mongodb-cert.crt"
	mongoKeyFile="${mongoHome}/ssl/mongodb-cert.key"

	backupFile $mongoCrtFile "$sudo"
	backupFile $mongoKeyFile "$sudo"

	COUNTRY="IN"
	STATE="Karnataka"
	LOCALITY="Bangalore"
	COMPANY="Digital Harbor"
	ORGNAME="Platform"
	ORGUNIT="Platform QA"
	EMAIL="noreply@digitalharbor.com"

###
#runCmd "$sudo openssl req -newkey rsa:2048 -new -x509 -days 365 -nodes -out $mongoCrtFile -keyout $mongoKeyFile"
###


	echo
	echo " Running the command : "
	echo "$sudo openssl req -newkey rsa:2048 -new -x509 -days 365 -nodes -out $mongoCrtFile -keyout $mongoKeyFile"
	echo

cat <<__EOI__ | $sudo openssl req -newkey rsa:2048 -new -x509 -days 365 -nodes -out ${mongoCrtFile} -keyout ${mongoKeyFile}
$COUNTRY
$STATE
$LOCALITY
$COMPANY
$ORGNAME
$ORGUNIT
$EMAIL
__EOI__

#runCmd "$sudo openssl req -newkey rsa:2048 -new -x509 -days 365 -nodes -out $mongoCrtFile -keyout $mongoKeyFile"

	echo
	echo "Creating mongodb.pem file using Certificate and Key file generated earlier"
	echo


	backupFile $mongoPemFile "$sudo"

	runCmd "$sudo touch $mongoPemFile"
	runCmd "$sudo chmod -R 777 $mongoPemFile"

#runCmd "$sudo cat $mongoKeyFile $mongoCrtFile > $mongoPemFile"
#
### runCmd is mis-behaving to redirect the cat output to a file, run it directly for now
#
	cmd="$sudo cat $mongoKeyFile $mongoCrtFile > $mongoPemFile"
	echo
	echo "Running the command: $cmd"
	$sudo cat $mongoKeyFile $mongoCrtFile > $mongoPemFile
	echo "Done."
	echo

else
	echo "INFO: Using the pem file provided - $pemFile"
	if [ ! -r $pemFile ]
	then
		echo
		echo "ERROR: Unable to read pem file $pemFile"
		echo
		exit 1
	fi

	runCmd "cp $pemFile $mongoPemFile"

fi  # End of pem file creation


echo
echo "Generating certificate.der file, this is to be imported into Java8 used by DMS Wildfly."
echo "---------------------------------------------------------------------------------------"
echo


backupFile $mongoDerFile "$sudo"

runCmd "$sudo openssl x509 -outform der -in $mongoPemFile -out $mongoDerFile"

echo
echo "Note:"
echo "====="
echo "	Copy $mongoDerFile to the DMS Wildfly machine."
echo "You can use the script 4_import_client_cert.sh to import into <JAVA_HOME>/jre/lib/security/cacerts"
echo

mongodScript="${mongoHome}/mongodb/mongodb-linux-x86_64-ubuntu1404-3.2.4/bin/mongoDB_start.sh"
mongoScript="${mongoHome}/mongodb/mongodb-linux-x86_64-ubuntu1404-3.2.4/bin/mongoShell_start.sh"

ipAddress=`ifconfig | grep inet | head -1 | sed 's+inet addr:++g'| awk '{print \$1}'`

### Use --fork command to start mongod as a deamon
mongoDBStartCmd="mongod --sslMode requireSSL --sslPEMKeyFile $mongoPemFile  --dbpath=${mongoDataPath} --port ${mongoPort} --fork --logpath ${mongoHome}/mongodb/mongo.log --bind_ip $ipAddress"
mongoShellCmd="mongo --ssl --sslAllowInvalidCertificates --sslPEMKeyFile $mongoPemFile --port ${mongoPort} --host $ipAddress"


### Create the DMS repo and users

### Start the Mongo DB first

echo
echo "Starting the Mongo DB in background ....."
echo

export PATH=${mongoHome}/mongodb/mongodb-linux-x86_64-ubuntu1404-3.2.4/bin:$PATH

echo
echo "Using PATH : $PATH"
echo

cmd="$mongoDBStartCmd"

#cmd="$mongoDBStartCmd --fork --logpath ${mongoHome}/mongodb/mongo.log &"

### Command is not runing properly, let us run it from a temporary file

tempCmdFile="/tmp/cmd_${datestamp}.sh"

runCmd "rm -f $tempCmdFile"
echo "$cmd" > $tempCmdFile
runCmd "chmod 755 $tempCmdFile"

echo
echo "Running the command :"
cat $tempCmdFile

$tempCmdFile

echo
echo "Sleeping $sleepTime seconds for Mongo DB to come up ....."
sleep $sleepTime

### Check whether MongoDB is up and running successfully
mongodProcess=`ps -ef | grep -v grep | grep mongod | grep -v 2_install_MongoDB\.sh`

if [ "x${mongodProcess}" == "x" ]
then
	echo 
	echo "ERROR: MongoDB is not started successfully after $sleepTime seconds."
	echo "       Please check the log file or run with more sleep time (-sleep option) in case it takes longer."
	echo
	exit 1
fi


echo
echo "Starting a Mongo Shell and creating the DMS repository DB and user"
echo 

mongoUserScript="${scriptDir}/files/mongoUser.js"
mongoUserScriptTmpl="${scriptDir}/files/mongoUser.js_tmpl"

if [ ! -r $mongoUserScript ]
then
	echo
	echo "ERROR : Unable to read $mongoUserScript"
	echo
	exit 1
fi

### Update the MongoDB repository and user details
mongoUserScriptNew="/tmp/mongoUser_$$.js"

runCmd "cp $mongoUserScriptTmpl $mongoUserScriptNew"

replaceText $mongoUserScriptNew "%dms_user%" "$mongoUser"
replaceText $mongoUserScriptNew "%dms_pass%" "$mongoUserPass"
replaceText $mongoUserScriptNew "%dms_repo%" "$mongoDbName"


mongoUserScript=$mongoUserScriptNew



echo "Mongo Shell Commands used :"
echo "---------------------------"
cat $mongoUserScript

echo

cmd="$mongoShellCmd < $mongoUserScript"
runCmd "rm -f $tempCmdFile"
echo "$cmd" > $tempCmdFile
runCmd "chmod 755 $tempCmdFile"

echo
echo "Running the command :"
cat $tempCmdFile

$tempCmdFile



echo
echo "Creating MongoDB Database startup script ....."
echo
echo "export PATH=${mongoHome}/mongodb/mongodb-linux-x86_64-ubuntu1404-3.2.4/bin:$PATH" > $mongodScript
echo "$mongoDBStartCmd" >> $mongodScript
echo
echo "Creating Mongo Shell startup script ....."
echo 
echo "export PATH=${mongoHome}/mongodb/mongodb-linux-x86_64-ubuntu1404-3.2.4/bin:$PATH" > $mongoScript
echo "$mongoShellCmd" >> $mongoScript

echo
echo "Environment Details :"
echo "====================="
echo 
echo "Mongo HOME : ${mongoHome}/mongodb/mongodb-linux-x86_64-ubuntu1404-3.2.4"
echo
echo "Mongo Deamon startup script : $mongodScript"
echo "Command : "
cat $mongodScript
echo
echo "Mongo Shell launch command : $mongoScript"
echo "Command : "
cat $mongoScript
echo

echo 
echo "NOTE : Mongo DB is currently RUNNING in the background."
echo 
#mongodProcess=`ps -ef | grep -v grep | grep mongod`
echo
echo "Mongo DB Process : "
echo $mongodProcess
echo

echo "Logfile : ${mongoHome}/mongodb/mongo.log"

echo


#
### END
#
date=`date`
echo 
echo "Script end time : $date"
echo


echo
### Now exit gracefully
exit 0
