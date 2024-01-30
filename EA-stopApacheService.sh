#!/usr/bin/env zsh

result=$(apachectl stop 2>&1)
if [[ $result != "" ]]; then
    ## Apache is found to be disabled already
    echo "<result>Apache Disabled</result>"
else
    ## Apache was found enabled, now disabled. 
    echo "<result>Apache Disabled: Was Enabled</result>"
fi