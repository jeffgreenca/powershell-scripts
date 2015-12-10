$username = Read-Host "Enter your username"
$password = Read-Host "Enter your password (will be echo'd to screen)"
$domain = Read-Host "Enter domain suffix, if any"
$servers = Read-Host "Enter the list of hosts or vCenter servers, separated by spaces"
$servers -split " " | % { echo "Host: $_$domain" }
echo "About to add these hosts to the VICredentialStore..."
pause
$servers -split " " | % { New-VICredentialStoreItem -Host "$_$domain" -User $username -Password $password } 
echo "Done..."
