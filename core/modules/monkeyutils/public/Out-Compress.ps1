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


function Out-Compress {
    <#
        .SYNOPSIS
		https://stackoverflow.com/questions/53583677/unexpected-convertto-json-results-answer-it-has-a-default-depth-of-2

        .DESCRIPTION
		https://stackoverflow.com/questions/53583677/unexpected-convertto-json-results-answer-it-has-a-default-depth-of-2

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Out-Compress
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
        [String]$outFile
    )
    begin {
        try{
            $type = [PSObject].Assembly.GetType('System.Management.Automation.Serializer')
            $ctor = $type.GetConstructor('instance,nonpublic', $null, @([System.Xml.XmlWriter]), $null)
            #CreateNew
            $mode = "CreateNew"
            $fs = New-Object System.IO.FileStream $outFile, $mode, 'Write', 'None'
            $gz = New-Object System.IO.Compression.GZipStream $fs, ([System.IO.Compression.CompressionLevel]::Optimal)
            $sw = New-Object System.IO.StreamWriter $gz
            $xw = New-Object System.Xml.XmlTextWriter $sw
            $serializer = $ctor.Invoke($xw)
            Write-Verbose -Message ($Script:messages.GzipOutputMessage -f $outFile);
        }
        catch{
            Write-Debug -Message $_
            $type = $null
        }
    }
    process {
        if($null -ne $type){
            try {
                [void]$type.InvokeMember("Serialize", "InvokeMethod,NonPublic,Instance", $null, $serializer, [object[]]@($InputObject))
            } catch {
                Write-Debug -Message ($Script:messages.SerializationError -f $InputObject.GetType(), $_)
            }
        }
    }
    end {
        if($null -ne $type){
            [void]$type.InvokeMember("Done", "InvokeMethod,NonPublic,Instance", $null, $serializer, @())
            #$sw.ToString()
            $xw.Close()
            $sw.Dispose()
            Write-Debug -Message ($Script:messages.GzipOutputInfoMessage -f $outFile)
        }
    }
}
