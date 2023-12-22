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


function Get-MonkeyPowerBIBackendUri {
<#
        .SYNOPSIS
		Get PowerBI backend uri

        .DESCRIPTION
		Get PowerBI backend uri

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyPowerBIBackendUri
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	param()
    Begin{
        $backendUri = $null
        $uri = 'https://api.powerbi.com/powerbi/globalservice/v201606/environments/discover?client=powerbi-msolap'
        $clouds = @{
            AzurePublic = "GlobalCloud";
            AzureChina = "ChinaCloud";
            AzureGermany = "GermanyCloud";
            AzureUSGovernment = "USGovCloud";
        }
        if($null -ne (Get-Variable -Name O365Object -Scope Script -ErrorAction Ignore)){
            $cloutType = $clouds.Item($O365Object.initParams.Environment)
        }
        else{
            $cloutType = $clouds.Item('AzurePublic')
        }
    }
    Process{
        $param = @{
            Url = $uri;
            Method = 'Post';
            UserAgent = $O365Object.UserAgent;
            Verbose = $O365Object.Verbose;
            Debug = $O365Object.Debug;
            InformationAction = $O365Object.InformationAction;
        }
        $Object = Invoke-MonkeyWebRequest @param
        if($null -ne $Object -and $null -ne ($Object.PsObject.Properties.Item('environments'))){
            $PowerBICloud = $Object.environments.Where({$_.cloudName -eq $cloutType})
            if($PowerBICloud.Count -gt 0){
                try{
                    $backendUri = $PowerBICloud.services.Where({$_.name -eq 'powerbi-backend'}) | Select-Object -ExpandProperty endpoint
                    if($backendUri){
                        #Set resource
                        $rsrc = $PowerBICloud.services.Where({$_.name -eq 'powerbi-backend'}) | Select-Object -ExpandProperty resourceId
                        if($rsrc){
                            $msg = @{
				                MessageData = ("Updating PowerBI backend uri to {0}" -f $rsrc)
				                callStack = (Get-PSCallStack | Select-Object -First 1);
				                logLevel = 'info';
				                InformationAction = $O365Object.InformationAction;
				                Tags = @('PowerBIClusterUriError');
			                }
			                Write-Information @msg
                            $O365Object.Environment.PowerBI = $rsrc
                        }
                    }
                }
                catch{
                    $msg = @{
				        MessageData = ($message.PowerBIBackendError -f $O365Object.TenantID);
				        callStack = (Get-PSCallStack | Select-Object -First 1);
				        logLevel = 'warning';
				        InformationAction = $InformationAction;
				        Tags = @('PowerBIClusterUriError');
			        }
			        Write-Warning @msg
                    #Add verbose
                    $msg.MessageData = $_.Exception;
                    $msg.logLevel = 'verbose';
                    Write-Verbose @msg
                }
            }
        }
    }
    End{
        return $backendUri
    }
}