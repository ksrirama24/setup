#!/bin/bash


#
### Usage Function
#
usage()
{
	echo "
Usage :
./configure_CaseSummary_war.sh [-help] [propFile=<path to env.properties files>] 

Where:
propFile : Path to env.properties file 

Eg:
./configure_CaseSummary_war.sh 

./configure_CaseSummary_war.sh -propFile=/path/to/file/env.properties

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
echo " 		Script to configure Casesummary.war"
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

caseSummaryWar="${pfsHome}/jboss-5.1.0.GA/server/default/deploy/oms/applications/CaseSummary.war"

if [ ! -r "${caseSummaryWar}" ]
then
	echo
	echo "ERROR: Unable to read CaseSummary.war at ${caseSummaryWar}" 
	echo
	exit 1
fi

### Let us update the JAR now
tempDir="/tmp/caseSummary_${datestamp}"
runCmd "rm -rf $tempDir"

runCmd "unzip -qod $tempDir $caseSummaryWar"


jdbcPropFile="${tempDir}/WEB-INF/classes/jdbc.properties"

if [ ! -r $jdbcPropFile ]
then
        echo
        echo "ERROR: Unable to read jdbc.properties at $jdbcPropFile"
        echo
        exit 1
fi



### Get the Enrollment DB details from properties file
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

### Get the Portal DB details from properties file
portalDbHost=`grep ^\s*portal.db.hostname= $propFile | awk -F'=' '{print \$2}'`	
echo "New Portal DB Host : $portalDbHost"

portalDbPort=`grep ^\s*portal.db.port= $propFile | awk -F'=' '{print \$2}'`	
echo "New Portal DB Port : $portalDbPort"

portalDbName=`grep ^\s*portal.db.name= $propFile | awk -F'=' '{print \$2}'`	
echo "New Portal DB Name : $portalDbName"

portalDbUser=`grep ^\s*portal.db.username= $propFile | awk -F'=' '{print \$2}'`	
echo "New Portal DB user: $portalDbUser"

portalDbPass=`grep ^\s*portal.db.password= $propFile | awk -F'=' '{print \$2}'`	
echo "New Portal DB password: $portalDbPass"

portalSslValue=`grep ^\s*portal.db.ssl= $propFile | awk -F'=' '{print \$2}'`	
echo "New Portal DB SSL Value : $portalSslValue"

if [ "$portalSslValue" == "true" ]
then
	portalSslValue="/ssl=mandatory/sslTrusted=false"
else
	portalSslValue=""
fi
### Frame the JDBC connection string

enrolJdbcURL="JSQLConnect://${dbHost}:${dbPort}/databaseName=${dbName}/selectMethod=Cursor/asciiStringParameters=true${sslValue}"
portalJdbcURL="JSQLConnect://${portalDbHost}:${portalDbPort}/databaseName=${portalDbName}/selectMethod=Cursor/asciiStringParameters=true${portalSslValue}"


updateKeyValueWithSpace "$jdbcPropFile" "jdbc.url" "$enrolJdbcURL"
updateKeyValueWithSpace "$jdbcPropFile" "jdbc.username" "$dbUser"
updateKeyValueWithSpace "$jdbcPropFile" "jdbc.password" "$dbPass"

updateKeyValueWithSpace "$jdbcPropFile" "jdbc.portalUrl" "$portalJdbcURL"
updateKeyValueWithSpace "$jdbcPropFile" "jdbc.portalUsername" "$portalDbUser"
updateKeyValueWithSpace "$jdbcPropFile" "jdbc.portalPassword" "$portalDbPass"

### Let us update the WAR file now
currDir=`pwd`

cd $tempDir
runCmd "zip -u $caseSummaryWar WEB-INF/classes/jdbc.properties"

cd $currDir

#
### END
#
endTime


### Now exit gracefully
exit 0