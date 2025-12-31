set sh1 to "launchctl unload -w /Library/LaunchDaemons/com.xconnect.service.plist;"
set sh2 to "/bin/rm /Library/LaunchDaemons/com.xconnect.service.plist;"
set sh3 to "/bin/rm /Library/LaunchAgents/com.xconnect.server.plist;"

set sh to sh1 & sh2 & sh3
do shell script sh with prompt "XConnect wants to unload daemon" with administrator privileges