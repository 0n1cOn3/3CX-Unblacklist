#!/bin/bash
# unblacklist
# made by Jersey Shore Technologies <info@jstechnologies.net>
# maintained by HERMES42 <info@hermes42.com> till March 2023.
# Continue to maintain it by 0n1cOn3 <0n1cOn3@gmx.ch> from April 2023 - now 
# V1.0 - 13.04.20223

#!/bin/bash

# FUNCTION: validate IP address
# Usage: validateIpAddress ip_addr
function validateIpAddress() {
    local ip=$1
    local result=1

    # Make sure the IP address has four octets consisting of nothing but numbers
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then

        # Temporarily change the bash Internal Field Separator to a dot
        IFS_temp=$IFS
        IFS='.'
        
        # Split the IP address into an array of octets
        ip=($ip)

        # Restore the bash Internal Field Separator to its original value
        IFS=$IFS_temp

        # Check that each octet has a value lower than 255
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        
        # Save the status of this test
        result=$?
    fi

    echo $result
}

# FUNCTION: get database password for phonesystem user
# Usage: getDBPassword
function getDBPassword() {
    # Get the password from 3CX file
    DBPassword=$(grep MasterDBPassword /var/lib/3cxpbx/Bin/3CXPhoneSystem.ini | cut -d' ' -f3)
    
    if [[ $? -eq 1 ]]; then
        echo "I was unable to read the phonesystem user password."
        exit
    fi
}

# FUNCTION: delete IP address from blacklisted database
# Usage: deleteIpAddress ip_addr
function deleteIpAddress() {
    getDBPassword
    psql postgresql://phonesystem:$DBPassword@127.0.0.1/database_single << EOF
        delete from blacklist where ipaddr = '$ip_addr';
EOF
}

# MAIN PROGRAM
echo "3CX Unblacklist v1.0 - April 2023"
read -p "Enter the IP address to remove from the blacklisted database: " ip_addr

# Validate IP address
if [[ $(validateIpAddress "$ip_addr") -eq 1 ]]; then
    echo "The IP address you entered is incorrect."
    exit
fi

# Look for the IP address in the database and delete it
deleteIpAddress $ip_addr

echo "If this was successful, you must restart the phone system MC01 service by entering the following command:"
echo "service 3CXPhoneSystemMC01 restart"
echo "Once the service is restarted, you may try to re-login through the web interface"
