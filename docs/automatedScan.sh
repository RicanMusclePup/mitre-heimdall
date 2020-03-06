#!/bin/bash

today=`date +%Y-%m-%d.%H:%M:%S`;

# source 

#Example windows scan
sudo inspec exec [/path/to/windows/profile/you/want/to/run]/stig-microsoft-windows-server-2016-v1r4-baseline/ -t winrm://$username@[hostname or IP address] --password=$password --reporter cli json:[/path/to/directory/where/scans/are/saved/hostname or ipaddress]-$today.json

#repeat commands for specific windows hosts

#Example Linux scan

sudo inspec exec [/path/to/linux/profile/you/want/to/run]/inspec-profile-disa_stig-el7/ --attrs=[/path/to/linux/profile/you/want/to/run]/inspec-profile-disa_stig-el7/attributes.yml -t ssh://$usernam@[hostname or ip address] --sudo --sudo-password=$password --password=$password --reporter cli json:[/path/to/directory/where/scans/are/saved/hostname or ipaddress]-$today.json

# repeat command for specific linux hosts 


# Here is the command to push to the heimdall API. You must repeat for every file you wish to upload, which is the number of scans you are doing on your machine. Change the values in the [ and ]
# Brackets. 


curl -F "file=@[FILE_PATH]" -F "email=[EMAIL]" -F "api_key=[API_KEY]" http://localhost:3000/evaluation_upload_api