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

Function Get-MonkeyAzClassicAdministrator {
    <#
        .SYNOPSIS
		Get classic administrators from Azure

        .DESCRIPTION
		Get classic administrators from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzClassicAdministrator
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
	[CmdletBinding()]
	Param ()
    Begin{
        $all_classic_admins = New-Object System.Collections.Generic.List[System.Object]
        $classicAdmins = $null
        $Environment = $O365Object.Environment
        #Get resource management Auth
        $rmAuth = $O365Object.auth_tokens.ResourceManager
        #Get Azure config
        $azureApiAuthConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureAuthorization" } | Select-Object -ExpandProperty resource
    }
    Process{
        try{
            if($null -ne $rmAuth -and $null -ne $O365Object.current_subscription){
                $msg = @{
                    MessageData = ($message.ClassicAdminsInfoMessage -f $O365Object.current_subscription.subscriptionId);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('AzureRbacInfo');
                }
                Write-Information @msg
                $p = @{
		            Authentication = $rmAuth;
			        Provider = $azureApiAuthConfig.Provider;
			        ObjectType = "classicAdministrators";
			        Environment = $Environment;
			        ContentType = 'application/json';
			        Method = "GET";
			        APIVersion = $azureApiAuthConfig.api_version;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
		        }
		        $classicAdmins = Get-MonkeyRMObject @p
            }
            else{
                $msg = @{
                    MessageData = ($message.ClassicAdminsWarningMessage);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('AzureClassicAdminWarning');
                }
                Write-Warning @msg
                break
            }
        }
        catch{
            $msg = @{
                MessageData = ($_);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'error';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureClassicAdminError');
            }
            Write-Error @msg
            $msg = @{
                MessageData = ($_.Exception.StackTrace);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'debug';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                Tags = @('AzureClassicAdminDebugError');
            }
            Write-Debug @msg
        }
    }
    End{
        if($null -ne $classicAdmins){
            foreach ($classic_admin in $classicAdmins) {
			    $roles = $classic_admin.Properties.role.Split(";")
			    foreach ($role in $roles) {
				    #Create custom object
				    $classic_admin_obj = [hashtable]@{
					    emailAddress = $classic_admin.Properties.emailAddress
					    role = $role
					    rawObject = $classic_admin
				    }
                    #Create new PsObject
                    $classic_admin_obj = New-Object -TypeName PsObject -Property $classic_admin_obj
				    #Decorate object and add to list
				    $classic_admin_obj.PSObject.TypeNames.Insert(0,'Monkey365.Azure.ClassicAdministrators')
                    #Add to array
				    [void]$all_classic_admins.Add($classic_admin_obj)
			    }
		    }
        }
        #Return classic admin obj
        return $all_classic_admins
    }
}
