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

function Get-OSVersion {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-OSVersion
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Begin{
        #Set constants
        $Windows = [System.Runtime.InteropServices.OSPlatform]::Windows
        try{
            $Linux = [System.Runtime.InteropServices.OSPlatform]::Linux
        }
        catch{
            $Linux = $null
        }
        try{
            $OSX = [System.Runtime.InteropServices.OSPlatform]::OSX
        }
        catch{
            $OSX = $null
        }
        try{
            $FREEBSD = [System.Runtime.InteropServices.OSPlatform]::FreeBSD
        }
        catch{
            $FREEBSD = $null
        }
    }
    Process{
        try{
            if([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform($Windows)){
                $OS = $Windows
            }
            elseif([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform($Linux)){
                $OS = $Linux
            }
            elseif([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform($OSX)){
                $OS = $OSX
            }
            elseif([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform($FREEBSD)){
                $OS = $FREEBSD
            }
            else{
                $OS = "Unknown"
            }
        }
        catch{
            Write-Warning ('Unable to get OS')
            $OS = 'Unknown'
        }
    }
    End{
        return $OS.ToString().ToLower()
    }
}
