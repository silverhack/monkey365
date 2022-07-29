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

function Copy-psObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Copy-psObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(Mandatory=$true, HelpMessage="Object to copy to")]
        [Object]$object
    )
    try{
        if($object){
            $memory_stream = New-Object System.IO.MemoryStream
            $binary_formatter = New-Object System.Runtime.Serialization.Formatters.Binary.BinaryFormatter
            $binary_formatter.Serialize($memory_stream, $object)
            $memory_stream.Position = 0
            $shadow_object = $binary_formatter.Deserialize($memory_stream)
            $memory_stream.Close()
            #return cloned object
            return $shadow_object
        }
    }
    catch{
        Write-Warning -Message ("Unable to clone object")
        #Verbose
        Write-Verbose -Message $_.Exception
        #return null object
        return $null
    }
}
