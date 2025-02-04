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


function Export-DataToCliXml {
    <#
        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Export-DataToCliXml
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory=$true, HelpMessage="File")]
        [String]$Path
    )
    Begin {
        $sw = $xw = $null
        $type = [PSObject].Assembly.GetType('System.Management.Automation.Serializer')
        $ctor = $type.GetConstructor('instance,nonpublic', $null, @([System.Xml.XmlWriter]), $null)
        #CreateNew
        $mode = "CreateNew"
        $fs = New-Object System.IO.FileStream $Path, $mode, 'Write', 'None'
        $sw = [System.IO.StreamWriter]::new($fs)
        $xw = [System.Xml.XmlTextWriter]::new($sw)
        $serializer = $ctor.Invoke($xw)
        Write-Verbose -Message ($Script:messages.CliXmlOutputMessage -f $Path);
    }
    Process {
        Try{
            #Serialize elements
            Try {
                [void]$type.InvokeMember("Serialize", "InvokeMethod,NonPublic,Instance", $null, $serializer, [object[]]@($InputObject))
            } Catch {
                Write-Verbose -Message ($Script:messages.SerializationError -f $InputObject.GetType(), $_)
            }
        }
        Catch{
            Write-Verbose -Message $_
        }
    }
    End {
        [void]$type.InvokeMember("Done", "InvokeMethod,NonPublic,Instance", $null, $serializer, @())
        $xw.Close()
        $sw.Dispose()
    }
}


