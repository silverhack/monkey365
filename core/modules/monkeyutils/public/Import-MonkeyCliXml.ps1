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

function Import-MonkeyCliXml {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Import-MonkeyCliXml
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding(DefaultParametersetName="File")]
    Param (
        [Parameter(Position=0, Mandatory=$True, ParameterSetName = 'File', ValueFromPipeline = $True)]
        [String]$File,

        [Parameter(Position=1, Mandatory=$True, ParameterSetName = 'RawData', ValueFromPipeline = $True)]
        [Object]$RawData

    )
    Begin{
        $xr = $sr = $null
    }
    Process{
        try{
            If($PSCmdlet.ParameterSetName -eq 'File'){
                if (!(Test-Path -Path $File)){
                    Write-Warning ("The path {0} does not exists" -f $File)
                    return $null
                }
                else{
                    $fs = [IO.File]::OpenRead($File)
                    $sr = [IO.StreamReader]::new($local:fs)
                    $xr = [System.Xml.XmlTextReader]::new($sr)
                }
            }
            else{
                $b = [System.Text.Encoding]::ASCII.GetBytes($RawData)
                $ms = [System.IO.MemoryStream]::new($b)
                $sr = [IO.StreamReader]::new($ms)
                $xr = [System.Xml.XmlTextReader]::new($sr)
            }
            $type = [PSObject].Assembly.GetType('System.Management.Automation.Deserializer')
            $ctor = $type.GetConstructor('instance,nonpublic', $null, @([xml.xmlreader]), $null)
            $deserializer = $ctor.Invoke($xr)
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
        catch{
            Write-Error $_
        }
    }
    End{
        if($null -ne $xr -and $null -ne $sr){
            $xr.Close()
            $sr.Dispose()
        }
    }
}
