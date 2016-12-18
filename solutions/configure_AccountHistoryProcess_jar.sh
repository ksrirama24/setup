#!/bin/bash


#
### Usage Function
#
usage()
{
	echo "
Usage :
./configure_AccountHistoryProcess_jar.sh [-help] [propFile=<path to env.properties files>] 

Where:
propFile : Path to env.properties file 

Eg:
./configure_AccountHistoryProcess_jar.sh 

./configure_AccountHistoryProcess_jar.sh -propFile=/path/to/file/env.properties

Note:
The script needs to be run in bash shell

"
	
}


#
### Parse the command line arguments
#
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | -help)
            usage
            exit
            ;;
        -propFile)
            propFile=$VALUE
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
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " 		Script to configure AccountHistoryProcess.jar"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
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

scriptDir=`dirname ${scriptDir}`

echo "Script dir : $scriptDir"

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

#
### Starting Time
startTime


export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$PATH"

echo
echo
echo "Using PATH : $PATH"
echo
echo


if [ "x${propFile}" == "x" ]
then

	echo
	echo
	echo "Enter the env.properties location :"
	read propFile
fi



if [ ! -r $propFile ]
then
	echo
	echo "ERROR: Unable to read properties file at $propFile"
	echo
	exit 1
fi


echo
echo
echo "Property file supplied : $propFile"
echo
echo
if [ ! -r $propFile ]
then
	echo
	echo "ERROR: Unable to read properties file $propFile"
	echo
	exit 1
fi

getKeyValue "$propFile" "pfs.home"
pfsHome=$value

	

if [ "x${pfsHome}" == "x" ]
then
	echo
	echo "ERROR: Unable to read PFS_HOME location from properties file "
	echo
	exit 1
fi

echo
echo
echo "Environment Details :"
echo
echo "PFS_HOME : $pfsHome"


echo
echo


#
### For patch installer, let us use the JDK present under the PFS_HOME

if [ ! -d $pfsHome ]
then
	echo
	echo "ERROR: Unable to read the PFS_HOME directory $pfsHome."
	echo
	exit 1
fi

accHistJar="${pfsHome}/jboss-5.1.0.GA/server/default/lib/AccountHistoryProcess.jar"

if [ ! -r "${accHistJar}" ]
then
	echo
	echo "ERROR: Unable to read AccountHistoryProcess.jar at ${accHistJar}" 
	echo
	exit 1
fi

### Let us update the JAR now
tempDir="/tmp/accHistJar_${datestamp}"
runCmd "rm -rf $tempDir"

runCmd "unzip -qod $tempDir $accHistJar"


hibernateXml="${tempDir}/hibernate.cfg.xml"
hibernateXmlBak="${scriptDir}/files/hibernate.cfg_bak.xml"
hibernateXmlTmpl="${scriptDir}/files/hibernate.cfg_tmpl.xml"

if [ ! -r $hibernateXml ]
then
        echo
        echo "ERROR: Unable to read hibernate.cfg.xml at $hibernateXml"
        echo
        exit 1
fi

if [ ! -r $hibernateXmlBak ]
then
        echo
        echo "ERROR: Unable to read hibernate.cfg_bak.xml at $hibernateXmlBak"
        echo
        exit 1
fi


if [ ! -r $hibernateXmlTmpl ]
then
        echo
        echo "ERROR: Unable to read hibernate.cfg_tmpl.xml Template at $hibernateXmlTmpl"
        echo
        exit 1
fi

compareFile "$hibernateXml" "$hibernateXmlBak"

if [ $? -ne 0 ]
then
        echo
        echo "INFO : Looks like hibernate.cfg.xml used for templatization has changed. The script may not work properly."
        echo
        exit 1
fi

### Let us copy the template file to tmp location
runCmd "cp $hibernateXmlTmpl $hibernateXml"



portalXml="${tempDir}/portal.cfg.xml"
portalXmlBak="${scriptDir}/files/portal.cfg_bak.xml"
portalXmlTmpl="${scriptDir}/files/portal.cfg_tmpl.xml"

if [ ! -r $portalXml ]
then
        echo
        echo "ERROR: Unable to read portal.cfg.xml at $portalXml"
        echo
        exit 1
fi

if [ ! -r $portalXmlBak ]
then
        echo
        echo "ERROR: Unable to read portal.cfg_bak.xml at $portalXmlBak"
        echo
        exit 1
fi


if [ ! -r $portalXmlTmpl ]
then
        echo
        echo "ERROR: Unable to read portal.cfg_tmpl.xml Template at $portalXmlTmpl"
        echo
        exit 1
fi

compareFile "$portalXml" "$portalXmlBak"

if [ $? -ne 0 ]
then
        echo
        echo "INFO : Looks like portal.cfg.xml used for templatization has changed. The script may not work properly."
        echo
        exit 1
fi

### Let us copy the template file to tmp location
runCmd "cp $portalXmlTmpl $portalXml"



getKeyValue "$propFile" "db.hostname"
dbHost=$value
echo "New DB Host : $dbHost"


getKeyValue "$propFile" "db.port"
dbPort=$value
echo "New DB Port : $dbPort"


getKeyValue "$propFile" "db.name"
dbName=$value
echo "New DB Name : $dbName"


getKeyValue "$propFile" "db.username"
dbUser=$value
echo "New DB user: $dbUser"


getKeyValue "$propFile" "db.password"
dbPass=$value
echo "New DB password: $dbPass"


getKeyValue "$propFile" "db.ssl"
sslValue=$value
echo "New SSL Value : $sslValue"

if [ "$sslValue" == "true" ]
then
	sslValue="/ssl=mandatory/sslTrusted=false"
else
	sslValue=""
fi

replaceText $hibernateXml "%db_host%" "$dbHost"
replaceText $hibernateXml "%db_port%" "$dbPort"
replaceText $hibernateXml "%db_name%" "$dbName"
replaceText $hibernateXml "%ssl_value%" "$sslValue"
replaceText $hibernateXml "%db_username%" "$dbUser"
replaceText $hibernateXml "%db_password%" "$dbPass"



### Get the Portal DB details from properties file
getKeyValue "$propFile" "portal.db.hostname"
portalDbHost=$value
echo "New Portal DB Host : $portalDbHost"


getKeyValue "$propFile" "portal.db.port"
portalDbPort=$value
echo "New Portal DB Port : $portalDbPort"


getKeyValue "$propFile" "portal.db.name"
portalDbName=$value
echo "New Portal DB Name : $portalDbName"


getKeyValue "$propFile" "portal.db.username"
portalDbUser=$value
echo "New Portal DB user: $portalDbUser"


getKeyValue "$propFile" "portal.db.password"
portalDbPass=$value
echo "New Portal DB password: $portalDbPass"


getKeyValue "$propFile" "portal.db.ssl"
portalSslValue=$value
echo "New Portal DB SSL Value : $portalSslValue"

if [ "$portalSslValue" == "true" ]
then
        portalSslValue="/ssl=mandatory/sslTrusted=false"
else
        portalSslValue=""
fi




replaceText $portalXml "%db_host%" "$portalDbHost"
replaceText $portalXml "%db_port%" "$portalDbPort"
replaceText $portalXml "%db_name%" "$portalDbName"
replaceText $portalXml "%ssl_value%" "$portalSslValue"
replaceText $portalXml "%db_username%" "$portalDbUser"
replaceText $portalXml "%db_password%" "$portalDbPass"


### AWSCredentials.properties
#
#
# Let us create the file newly.
#
#
#accessKey=AKIAIU3C44QELASU4BHA
#secretKey=w4AW36vETGSDxoXdOqfDMiPSCbmVBW3mj8FCU/Qv
#dynamoDbEndPoint=https://dynamodb.us-west-2.amazonaws.com
#Region=US_WEST_2

awsCredPropFile="${tempDir}/AWSCredentials.properties"


getKeyValue "$propFile" "aws.accessKey"
accessKey=$value

getKeyValue "$propFile" "aws.secretKey"
secretKey=$value

getKeyValue "$propFile" "aws.dynamoDbEndPoint"
dynamoDbEndPoint=$value

getKeyValue "$propFile" "aws.region"
region=$value


runCmd "rm -f $awsCredPropFile"

echo
echo "Creating AWSCredentials.properties file ....."

echo "
accessKey=${accessKey}
secretKey=${secretKey}
dynamoDbEndPoint=${dynamoDbEndPoint}
Region=${region}
" > ${awsCredPropFile}

echo "Done."
echo


### Let us update the JAR file now

currDir=`pwd`

cd $tempDir
runCmd "zip -u $accHistJar hibernate.cfg.xml"
runCmd "zip -u $accHistJar portal.cfg.xml"
runCmd "zip -u $accHistJar AWSCredentials.properties"

cd $currDir

#
### END
#
endTime


### Now exit gracefully
exit 0
