#!/usr/bin/env zsh

pSSOeStatus=$(app-sso platform -s)

########## CHECKING DEVICE CONFIGURATION ##########
if echo "$pSSOeStatus" | grep -q "^Device.Configuration:\n.\(null\)"; then
    pSSOeDevice="False"
else
    pSSOeDevice="True"
fi
########## CHECKING LOGIN CONFIGURATION ##########
if echo "$pSSOeStatus" | grep -q "^Login.Configuration:\n.\(null\)"; then
    pSSOeLogin="False"
else
    pSSOeLogin="True"
fi
########## CHECKING USER CONFIGURATION ##########
if echo "$pSSOeStatus" | grep -q "^User.Configuration:\n.\(null\)"; then
    pSSOeUser="False"
else
    pSSOeUser="True"
fi

########## CHECKING DEVICE CONFIGURATION ##########
if [[ "$pSSOeDevice" == "True" || "$pSSOeLogin" == "True" || "$pSSOeUser" == "True" ]]; then
    printf "<result>Device Configuration: %s\nLogin Configuration: %s\nUser Configuration: %s</result>" $pSSOeDevice $pSSOeLogin $pSSOeUser
else
    printf "<result>Platform SSOe Not Configured</result>"
fi

exit 0