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


Function Get-MonkeyMSGraphDirectoryObjectById{
    <#
        .SYNOPSIS
		Get directory objects specified in a list of IDs

        .DESCRIPTION
		Get directory objects specified in a list of IDs

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphDirectoryObjectById
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
	Param (
        [Parameter(Mandatory=$true, ValueFromPipeline = $True)]
        [String[]]$Ids,

        [parameter(Mandatory=$false)]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
        $dataDict = [ordered]@{
            ids = $null;
        }
    }
    Process{
        try{
            $all_ids = New-Object System.Collections.Generic.List[System.String]
            foreach($id in $Ids.GetEnumerator()){
                [void]$all_ids.Add($id)
            }
            $dataDict.ids = $all_ids.ToArray()
            $postData = $dataDict | ConvertTo-Json
            #Construct query
            $params = @{
                Authentication = $graphAuth;
                ObjectType = 'directoryObjects/getByIds';
                Environment = $Environment;
                Method = "Post";
                Data= $postData;
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $response = Get-MonkeyMSGraphObject @params
            if($response){
                return $response
            }
        }
        catch{
            $msg = @{
			    MessageData = ($message.MSGraphDirectoryObjectError);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'verbose';
			    InformationAction = $InformationAction;
			    Tags = @('DirectoryObjectError');
		    }
		    Write-Verbose @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            $msg.Tags+= "DirectoryObjectError"
		    Write-Verbose @msg
        }
    }
    End{
        #Nothing to do here
    }
}


