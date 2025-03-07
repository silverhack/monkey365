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


function ConvertTo-MonkeyObject{
    <#
        .SYNOPSIS
		Create new PsObject

        .DESCRIPTION
		Create new PsObject

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: ConvertTo-MonkeyObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$Objects

        )
    Begin{
        #create psobject
        $returnObject = [hashtable]::Synchronized(@{})
    }
    Process{
        try{
            foreach($object in $Objects.GetEnumerator()){
                if($object -is [System.Collections.DictionaryEntry] -and $object.psobject.properties.name -contains "Name" -and $object.psobject.properties.name -contains "Value"){
                    $returnObject.Add($object.Name,$object.Value)
                }
            }
        }
        catch{
            $msg = @{
                MessageData = $message.ConvertObjectErrorMessage;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureConvertObjectError');
            }
            Write-Warning @msg
            #Write Debug
            $msg = @{
                MessageData = $_;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'debug';
                InformationAction = $InformationAction;
                Tags = @('AzureConvertObjectError');
            }
            Write-Debug @msg
        }
    }
    End{
        if($returnObject){
            return $returnObject
        }
    }
}


