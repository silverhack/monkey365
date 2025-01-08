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

Function Get-MonkeySystemInfo {
    [CmdletBinding(ConfirmImpact = 'None')]
    [OutputType([System.Management.Automation.PSObject])]
    param ()
    Begin{
        #Create PsCustomObject
        $sysObj = [PsCustomObject]@{
            OsType = $null;
            IsAdmin = $null;
            MsalType = $null;
            OSVersion = $null;
            ProcArch = $null;
            OSArch = $null;
        }
    }
    Process{
        If ($PSVersionTable.PSEdition -eq 'Desktop'){
            $sysObj.IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
            $sysObj.OsType = 'Windows'
            $sysObj.MsalType = 'Desktop'
        }
        Elseif (($PSVersionTable.PSEdition -eq 'Core') -and ($PSVersionTable.Platform -eq 'Unix')){
            If ((id -u) -eq 0){
                $sysObj.IsAdmin = $true
            }
            else{
                $sysObj.IsAdmin = $false
            }
            $sysObj.OsType = 'Unix'
            $sysObj.MsalType = 'Core'
        }
        Elseif (($PSVersionTable.PSEdition -eq 'Core') -and ($PSVersionTable.Platform -eq 'Win32NT')){
            $sysObj.IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
            $sysObj.OsType = 'Windows'
            $sysObj.MsalType = 'Core'
        }
        Else{
            Write-Warning -Message 'Unable to get System Information'
        }
        #Get Process architecture
        try{
            $sysObj.ProcArch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
        }
        catch{
            Write-Warning -Message 'Unable to get process architecture'
        }
        #Get OS architecture
        try{
            $sysObj.OSArch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
        }
        catch{
            Write-Warning -Message 'Unable to get OS architecture'
        }
    }
    End{
        return $sysObj
    }
}
