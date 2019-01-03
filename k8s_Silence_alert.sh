#!/bin/bash
#
#NAME:       k8s_Silience_alert
#AUTHOR:     Chris Danielewski 
#DATE  :     12/31/2018 
#PURPOSE:    This function will silence alert manager with one or two key:value types					                                                                                         
#OUTPUT:     N/A
#
#REQUIRED UTILITIES: shell, network access to alertmanager
#REQUIRED INPUT:
#$1 - stack, eg. s1,qa-sa
#$2 - key, eg. TargetDown
#$3 - value eg. kubelet
#$4 - time in munutes eg. 20
#$5,$6 optional for nested key/value pair eg. instace = IP
#USAGE EXAMPLE: k8s_Silence_alert <cluster> TargetDown kubelet 5
#==========================================================================
#CHANGE HISTORY:
#GE HISTORY:
#v1.0                       12/31/2018          CD                  New script!
#v1.1                       02/01/2019          CD                  Date format (coreOS)
## Required values
stack=$1
key=$2
value=$3
minutes=$4
## Additional Values if needed
nested_k=$5
nested_val=$6

### Obtain correct alert template
if [ -z "$nested_k" ]
  then
### Copy Alert
    cp alert.json /root/newalert.json
  else
### Copy Alert
    cp alert_plus.json /root/newalert.json
fi
### Date
formatteddate=`date '+%Y-%m-%dT%H:%M:%S.000Z'`
enddate=`date --date="+$minutes minutes" '+%Y-%m-%dT%H:%M:%S.000Z'`
#enddate=`date -v+"$minutes"M '+%Y-%m-%dT%H:%M:%S.000Z'` MacOS syntax
### SED start and end and values
thisalert=/root/newalert.json
sed -i -e "s/START/$formatteddate/" $thisalert
sed -i -e "s/END/$enddate/" $thisalert
sed -i -e "s/KEY/$key/" $thisalert
sed -i -e "s/VALUE/$value/" $thisalert
### Check if more key pairs are needed
if [ -z "$nested_k" ]
  then
    ### POST
    curl -k -d @"$thisalert" -X POST https://alertmanager.admin.$stack.domain.com/api/v1/silences
  else
    sed -i -e "s/NESTED_K/$nested_k/" $thisalert
    sed -i -e "s/NESTED_VAL/$nested_k/" $thisalert
    ### POST
    curl -k -d @"$thisalert" -X POST https://alertmanager.admin.$stack.domain.com/api/v1/silences
fi

## Cleanup
rm $thisalert
if [ -f /root/newalert.json-e ]; then
  rm /root/newalert.json-e
fi
if [ -f /root/alert.json-e ]; then
  rm /root/alert.json-e
fi


