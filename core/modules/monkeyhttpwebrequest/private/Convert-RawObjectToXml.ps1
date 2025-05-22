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

Function Convert-RawObjectToXml{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Convert-RawObjectToXml
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$True, HelpMessage='Raw Object')]
        [Object]$RawObject
    )
    try{
        $StrWriter = New-Object System.IO.StringWriter
        $DataDoc = New-Object system.xml.xmlDataDocument
        $DataDoc.LoadXml($RawObject)
        $Writer = New-Object system.xml.xmltextwriter($StrWriter)
        #Indented Format
        $Writer.Formatting = [System.xml.formatting]::Indented
        $DataDoc.WriteContentTo($Writer)
        #Flush Data
        $Writer.Flush()
        $StrWriter.flush()
        #Return data
        return $StrWriter.ToString()
    }
    catch{
        Write-Debug -Message $script:messages.UnableToConvertToXml
        return $null
    }
}

