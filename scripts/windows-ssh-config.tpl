add-content -path C:\Users\Philip\.ssh\config -value @"

Host ${hostname}
  HostName ${hostname}
  User ${user}
  IdentityFile ${identityFile}
"@