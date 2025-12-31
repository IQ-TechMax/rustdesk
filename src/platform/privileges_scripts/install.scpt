on run {daemon_file, agent_file, user}

  set sh1 to "echo " & quoted form of daemon_file & " > /Library/LaunchDaemons/com.xconnect.service.plist && chown root:wheel /Library/LaunchDaemons/com.xconnect.service.plist;"

  set sh2 to "echo " & quoted form of agent_file & " > /Library/LaunchAgents/com.xconnect.server.plist && chown root:wheel /Library/LaunchAgents/com.xconnect.server.plist;"

  set sh3 to "cp -rf /Users/" & user & "/Library/Preferences/com.xconnect.XConnect/RustDesk.toml /var/root/Library/Preferences/com.xconnect.XConnect/;"

  set sh4 to "cp -rf /Users/" & user & "/Library/Preferences/com.xconnect.XConnect/RustDesk2.toml /var/root/Library/Preferences/com.xconnect.XConnect/;"

  set sh5 to "launchctl load -w /Library/LaunchDaemons/com.xconnect.service.plist;"

  set sh to sh1 & sh2 & sh3 & sh4 & sh5

  do shell script sh with prompt "XConnect wants to install daemon and agent" with administrator privileges
end run
