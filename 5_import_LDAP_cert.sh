#!/bin/bash

#
### Usage Function
#
usage()
{
        echo "
Usage :
./5_import_LDAP_cert.sh [-help] [-releaseLocation=<Release Bits Location>] [-ldapHost=<LDAP Hostname>] [-ldapPort=<LDAP Port number>] [-javaHome=<JAVA_HOME location>] [-silent]  [-propFile=<properties file>]

Where:
releaseLocation : Release Bits Location -- Default : NONE
ldapHost        : LDAP Hostname -- Default : 192.168.4.2
ldapPort        : LDAP Port Number -- Default : 636
javaHome        : JAVA_HOME location -- Default : NONE
propFile        : Properties file containing key-value pairs for all the environment details. Command line argument overrides values in properties file.
prompt          : Do not prompt for inputs, use default values


Eg:
./5_import_LDAP_cert.sh

./5_import_LDAP_cert.sh  -help

./5_import_LDAP_cert.sh  -releaseLocation=/home/dh/Release/79210

./5_import_LDAP_cert.sh -releaseLocation=/home/dh/Release/79210 -ldapHost=192.168.4.2 -ldapPort=636 -javaHome=/home/dh/PFS/TEST/jdk1.6.0_17

Note:
The script needs to be run in bash shell

"

} # End of function usage




echo
echo "Script to import the LDAP certificate to <JAVA_HOME>/jre/lib/security/cacerts"
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
        -releaseLocation)
            releaseLocation=$VALUE
            ;;
        -silent)
            silent="true"
            ;;
        -ldapHost)
            ldapHost=$VALUE
            ;;
        -ldapPort)
            ldapPort=$VALUE
            ;;
        -javaHome)
            javaHome=$VALUE
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

###############################################################################################################################
if [ "x${silent}" = "x" ]
then
        silent="false"
fi


if [ "x${releaseLocation}" == "x" ] && [ "$silent" == "false" ]
then
	echo
	echo "Enter the release location : "
	read releaseLocation
fi


if [ "x${ldapHost}" == "x" ] && [ "$silent" == "false" ]
then
	echo
	echo "Enter the LDAP Hostname [Default : 192.168.4.2]:"
	read ldapHost
	echo
fi


if [ "x${ldapHost}" == "x" ]
then
	ldapHost="192.168.4.2"
	echo
	echo "INFO : LDAP Hostname is not supplied. Using the default hostname $ldapHost."
	echo
else
	echo
	echo "INFO : Using the LDAP hostname $ldapHost."
	echo
fi

if [ "x${ldapPort}" == "x" ] && [ "$silent" == "false" ]
then
	echo "Enter the LDAP Port number [Default : 636]:"
	read ldapPort
	echo
fi


if [ "x${ldapPort}" == "x" ]
then
	ldapPort="636"
	echo
	echo "INFO : LDAP port number is not supplied. Using the default port number $ldapPort."
	echo
else
	echo
	echo "INFO : Using the LDAP port number $ldapPort."
	echo
fi

if [ "x${javaHome}" == "x" ] && [ "$silent" == "false" ]
then
	echo "Enter the JAVA_HOME location :"
	read javaHome
	echo
fi

if [ "x${javaHome}" == "x" ]
then
	echo
	echo "ERROR: JAVA_HOME is not defined. JAVA_HOME is a mandatory requirement, no defaults can be used"
	echo
	exit 1
fi

echo
echo "INFO : Using the JAVA_HOME location : $javaHome"
echo


if [ "x${releaseLocation}" == "x" ]
then
	echo
	echo "ERROR: Release location is not supplied. Release location is a mandatory requirement, no defaults can be used"
	echo
	exit 1
fi



if [ ! -r ${javaHome}/jre/lib/security/cacerts ]
then
	echo "ERROR: Unable to read ${javaHome}/jre/lib/security/cacerts"
	echo
	exit 1
fi

installCertJar="${releaseLocation}/installcert.jar"

if [ ! -r $installCertJar ]
then
	echo
	echo "ERROR : Unable to read installcert.jar at $installCertJar"
	echo
	exit 1
fi


#/home/dh/Dinesh/Java_JDK1.6/jdk1.6.0_17/bin/java -jar "/home/dh/Dinesh/InstallCert/InstallCert/installcert.jar" "192.168.4.192" "636" "/home/dh/Gajanana_PFS791_23March/jdk1.6.0_17/jre/lib/security/cacerts" "changeit" 


# Now try to import 

cmd="${javaHome}/bin/java -jar ${installCertJar} $ldapHost $ldapPort ${javaHome}/jre/lib/security/cacerts changeit"


echo "Running the command : $cmd"
echo | $cmd
exit $?
