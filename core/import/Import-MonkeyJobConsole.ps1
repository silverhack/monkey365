# Monkey365 - the PowerShell Cloud Security Tool for Azure and Microsoft 365 (copyright 2022) by Juan Garrido
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Function Import-MonkeyJobConsole{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Import-MonkeyJobConsole
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$True, ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$Jobs
    )
    Begin{
        $selected_job = $null;
        try{
            $Jobs = $Jobs | Sort-Object {[system.datetime]::parse($_.date)} -Descending
            $choices = @()
            For($index = 0; $index -lt $Jobs.Count; $index++){
                $Jobs[$index] | Add-Member -type NoteProperty -name Id -value $index -Force
                [psobject]$s = @{
                    id = $index+1
                    displayName = $Jobs[$index].tenantName
                    date = $Jobs[$index].date
                    path = $Jobs[$index].jobFolder
                }
                $choices+=$s
            }
        }
        catch{
            Write-Information "Unable to create job choices"
            $msg = @{
                MessageData = $_.Exception;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'debug';
                InformationAction = $script:InformationAction;
                Tags = @('JobChoicesError');
            }
            Write-Debug @msg
            $choices = $null
        }
    }
    Process{
        if($null -ne $choices){
            while ($true) {
                $choices | Select-Object id, displayName, date, path | Format-Table -AutoSize | Out-Host
                $sbsID = Read-Host "Enter the [ID] number to select a Job. Type 0 or Q to quit."
                if ($sbsID -eq '0' -or $sbsID -eq 'Q') { break }  # exit from the loop, user quits
                # test if the input is numeric and is in range
                $badInput = $true
                if ($sbsID -notmatch '\D') {    # if the input does not contain an non-digit
                    $index = [int]$sbsID - 1
                    if ($index -ge 0 -and $index -lt $Jobs.Count) {
                        $badInput = $false
                        # everything OK, you now have the index to do something with the selected job
                        Write-Information ("You have selected {0} Job" -f $Jobs[$index].tenantName) -InformationAction $InformationAction
                        $selected_job = $Jobs[$index]
                        break
                    }
                }
                # if you received bad input, show a message, wait a couple
                # of seconds so the message can be read and start over
                if ($badInput) {
                    Write-Warning "Bad input received. Please type only a valid number from the [ID] column."
                    Start-Sleep -Seconds 4
                }
            }
        }
    }
    End{
        return $selected_job
    }
}
