# Automated script

- Create a config file where the profile you want to run is located, such as /path/to/profile/config.sh

- Once the config is created, inside of the profile create two variables as such

`username = insertUsernameHere`
`password = insertPasswordHere`

- Close and save the file, and then change the privelages of the file by running `sudo chmod 700 config.sh`

- Now open the automatedScan.sh provided in the heimdall/docs directory, open the file

- Upon opening the file, make sure you uncomment the source line and put the absolute path to your config.sh you just created above. You can figure out where that
  is by running `$ pwd` in the directory

- In both of the inspec commands, one for windows and one for linux, go ahead and **REMOVE** the brackets and **EDIT** the placeholders with absolute paths that
  point to the profile and where the scan will be saved.

- Repeat the above step for as many hosts you need to scan, but modify the hostname and name of .json files

- Once you have saved the file, go ahead and create a new cronjob using `sudo crontab -e`

**EXAMPLE** `0 2 * * 5 /path/to/automatedScan.sh`

The above example will run the scan every Friday at 2 AM as root. **This will not work if you do not run this script as Root, since config.sh requires root to read**

- Pushing to the API - You **MUST** create a new line for every scan that you do to individually upload each JSON object from the scan.
  **YOU CAN GET YOUR API KEY FROM THE HEIMDALL WEB APPLICATION FOR THE USER YOU ARE USING FROM CLICKING ON YOUR ICON ON THE TOP RIHGT AND CLICKING PROFILE IN THE DROP DOWN**

# Automated Powershell script

- First and foremost create a folder where you will you storing all of your scans and where the stig-microsoft-windows-server-2016-v1r4-baseline folder is located.

- Once inside of that folder, go ahead in a powershell window and run the command
  `read-host -assecurestring | convertfrom-securestring | out-file C:\PATH_TO_YOUR_SCANS_DIRECTORY\username.txt`

AND

`read-host -assecurestring | convertfrom-securestring | out-file C:\PATH_TO_YOUR_SCANS_DIRECTORY\password.txt`

MAKE SURE THAT THESE FILES ARE IN THE SAME FOLDER AS THE PROFILE YOU WILL BE RUNNING, THIS WILL BE YOUR STARTING POINT.

- Once those folders exist, you should be able to run the inspec scan, or automatedScan.ps1. This will locate these files you created and pull them into the script.

- You just need to schedule the script to run on Windows task scheduler, which will run the scans at the proper times and output it into it's own folders for date and time the scan was run.
