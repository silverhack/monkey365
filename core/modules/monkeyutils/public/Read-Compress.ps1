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

function Read-Compress {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Read-Compress
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
        [String]$Filename
    )
    Begin{
        $xr = $sr = $null
        if (!(Test-Path -Path $Filename)){
            Write-Warning ("The path {0} does not exists" -f $Filename)
            return $null
        }
        else{
            $fs = [IO.File]::OpenRead($Filename)
            $gz = New-Object IO.Compression.GZipStream $local:fs, ([System.IO.Compression.CompressionMode]::Decompress)
            $sr = New-Object IO.StreamReader $local:gz
            $xr = New-Object System.Xml.XmlTextReader $sr
        }
    }
    Process{
        if($null -ne $xr -and $null -ne $sr){
            $type = [PSObject].Assembly.GetType('System.Management.Automation.Deserializer')
            $ctor = $type.GetConstructor('instance,nonpublic', $null, @([xml.xmlreader]), $null)
            $deserializer = $ctor.Invoke($xr)
            #$done = $type.GetMethod('Done', [System.Reflection.BindingFlags]'nonpublic,instance')
            while (!$type.InvokeMember("Done", "InvokeMethod,NonPublic,Instance", $null, $deserializer, @()))
            {
                try {
                    $type.InvokeMember("Deserialize", "InvokeMethod,NonPublic,Instance", $null, $deserializer, @())
                } catch {
                    Write-Warning -Message ("Could not deserialize {0}: {1}" -f ${string}, $_)
                    return $null;
                }
            }
        }
    }
    End{
        if($null -ne $xr -and $null -ne $sr){
            $xr.Close()
            $sr.Dispose()
        }
    }
}


