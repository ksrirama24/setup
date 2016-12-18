#!/bin/sh

############################################################
#
# 8th Dec 2016 - sukanya - Initial Version
#
#
#
#
############################################################

usage()
{
        echo "
Usage :
./wildfly_details.sh [-help] [-wildflyHome=<wildfly install location>]

Where:
wildflyHome : wildfly Install location -- Default : NONE

Eg:
./wildfly_details.sh -wildflyHome=/home/dh/WILDFLY_TEST


Note:
The script needs to be run in bash shell

"

}
echo
#echo "Please Enter wildfly home location : "
### Parse the command line arguments
#
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
#    VALUE=`echo $1 | awk -F= '{print $2}'`
    VALUE=${1#${PARAM}=}
    case $PARAM in
        -h | -help)
            usage
            exit
            ;;
        -wildflyHome)
            wildflyHome=$VALUE
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

if [ ! -d ${wildflyHome}/wildfly-8.2.0 ]
then
        echo
        echo "ERROR: Unable to read the wildfly-8.2.0 directory at ${wildflyHome}/wildfly-8.2.0 ]"
        echo
        exit 1
fi


#read wildfly
echo
echo "------------------------"
echo "wildfly machine details"
echo "------------------------"
host=`hostname`
ipAddress=`ifconfig eth0| grep inet | head -1 | sed 's+inet addr:++g'| awk '{print \$1}'`
printf "%-50s %s \n" "Hostname" ": $host"
printf "%-50s %s \n" "Machine IP Address" ": $ipAddress"
echo "***********************************************************************************************************************************************"
echo
echo "Start script (start.sh) contents  "
echo "----------------------------------"
echo
cat ${wildflyHome}/wildfly-8.2.0/bin/start.sh
echo
echo "***********************************************************************************************************************************************"
echo
echo " java heap Memory                "
echo "---------------------------------"
echo
. ${wildflyHome}/wildfly-8.2.0/bin/standalone.conf
echo " java heap memory Parameters : $JAVA_OPTS"
echo
echo "***********************************************************************************************************************************************"
echo
echo "verify wether wildfly server is SSL enabled or not"
echo "---------------------------------------------------"
Conf_File="${wildflyHome}/wildfly-8.2.0/standalone/configuration/standalone.xml"
Conf_FileNoComments="${wildflyHome}/wildfly-8.2.0/standalone/configuration/standalone_NoComments.xml"
cat $Conf_File | sed '/<!--.*-->/d' | sed '/<!--/,/-->/d' > $Conf_FileNoComments
grep 'keystore path' $Conf_FileNoComments >/dev/null

if [ $? -ne 1 ]
then
        echo
        echo "INFO:Wildfly server is SSL enabled"
        echo
        
        echo " contents of identity.jks"
        echo "--------------------------"
        ${wildflyHome}/jdk1.8.0_72/bin/keytool -v -list -keystore ${wildflyHome}/wildfly-8.2.0/standalone/configuration/identity.jks -storepass password
        echo
echo "***********************************************************************************************************************************************"
   	echo    
        echo "checking wether SSL certificate imported to jdk cacerts"
        echo "-------------------------------------------------------"
        echo
        cert=`keytool  -list -keystore ${wildflyHome}/wildfly-8.2.0/standalone/configuration/identity.jks -storepass password | grep 'Certificate fingerprint'`
        echo "Certificate digest : $cert"
        keytool  -list -keystore ${wildflyHome}/jdk1.8.0_72/jre/lib/security/cacerts -storepass changeit | grep "$cert"
        if  test -n "$cert"
        then
          echo "INFO:certificate imported properly to cacerts"
        else
           echo " INFO:certificate is not imported"
        fi
else
        echo
        echo "INFO:wildfly server is not SSL enabled"
fi
echo
echo "***********************************************************************************************************************************************"
echo
echo " MongoDB Details"
echo "----------------"
echo
MONGODB=`grep mongo.connection.uri ${wildflyHome}/wildfly-8.2.0/standalone/configuration/dms-configuration.properties | grep -v ^#`
printf "%-10s %s \n" "MongoDB URL" ": $MONGODB"
echo
echo "***********************************************************************************************************************************************"
echo
echo "check wether reindexing flag updated in standalone.sh or not"
echo "------------------------------------------------------------"
echo
grep 'Doak.indexUpdate.ignoreReindexFlags' ${wildflyHome}/wildfly-8.2.0/bin/standalone.sh | grep -v ^# >/dev/null
if [ $? -ne 1 ]
        then
        echo "INFO: Reindexing flag is updated in standalone.sh"
else
        echo "INFO: Reindexing flas is not updated in standalone.sh"
fi
echo

