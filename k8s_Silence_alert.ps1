<#
NAME:      k8s_Silience_alert

AUTHOR:     Chris Danielewski 

DATE  :      10/04/2018 

PURPOSE:     This function will silence alert manager with one or two key:value types
		     It allows for minutes, hours, days for tsetting the expiry
					                                                                                         
OUTPUT:      N/A


REQUIRED UTILITIES: PowerCLI,

USAGE EXAMPLE: k8s_Silence_alert -stack <cluster> -key TargetDown -value kubelet -minutes 5
                        
==========================================================================
CHANGE HISTORY:
GE HISTORY:
v1.0                       10/04/2018          CD                  New script!
#>
param(
[Parameter(Mandatory=$true)][String]$stack,
[Parameter(Mandatory=$true)][String]$key,
[Parameter(Mandatory=$true)][string]$value,
[Parameter(Mandatory=$false)][string]$key2,
[Parameter(Mandatory=$false)][string]$value2,
[Parameter(Mandatory=$false)][int]$minutes,
[Parameter(Mandatory=$false)][int]$hours,
[Parameter(Mandatory=$false)][int]$days
)
 

###Find script location
$scriptdir = (get-item $PSScriptRoot).FullName
### Set Regex value to False
[bool]$fal = $false
### Obtain alert templat
$body = Get-Content -Raw "$scriptdir\alert.json" | ConvertFrom-Json
### Update alert match criteria
$body.matchers = @([pscustomobject]@{name=$key;value=$value;isRegex=$fal})

### Update alert match criteria if more than 1
if($key2){
$body.matchers = @([pscustomobject]@{name="$key";value="$value";isRegex=$fal},
[pscustomobject]@{name=$key2;value=$value2;isRegex=$fal})
}
#Date fun +6h since Prometheus is UTC, set start and end time based on params
$date = Get-Date
$start_date = $date.AddHours(6)
$start = [string]$start_date.Year + "-" + [string]$start_date.Month.ToString("00") + "-" + $start_date.Day.ToString("00") + "T" + $start_date.Hour.ToString("00") + ":" + $date.Minute.ToString("00") + ":" + $date.Second.ToString("00") + ".000Z"

if($minutes){
$end_date = $start_date.AddMinutes($minutes)}
if($hours){
$end_date = $start_date.AddHours($hours)}
if($days){
$end_date =$start_date.AddDays($days)}

$end =  [string]$end_date.Year + "-" + [string]$end_date.Month.ToString("00") + "-" + $end_date.Day.ToString("00") + "T" + $end_date.Hour.ToString("00") + ":" + $end_date.Minute.ToString("00") + ":" + $end_date.Second.ToString("00") + ".000Z"

$body.startsAt = $start
$body.endsAt = $end
## Post to alertmanager API
Invoke-RestMethod -Method Post -Uri "https://alertmanager.admin.$stack.domain.com/api/v1/silences" -Body (ConvertTo-Json $body)
Write-Host "API call sent"
}

$output = k8s_Silence_alert -stack $stack -key $key -value $value -key2 $key2 -value2 $value2 -minutes $minutes