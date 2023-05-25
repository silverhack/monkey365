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


function Get-MonkeyEXOOutboundSpamFilterPolicy {
<#
        .SYNOPSIS
		Plugin to get information about outbound spam filter policy in Exchange Online

        .DESCRIPTION
		Plugin to get information about outbound spam filter policy in Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXOOutboundSpamFilterPolicy
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false,HelpMessage = "Background Plugin ID")]
		[string]$pluginId
	)
	begin {
		$exo_outbound_spam_filter_policy = $null
		#Plugin metadata
		$monkey_metadata = @{
			Id = "exo0014";
			Provider = "Microsoft365";
			Resource = "ExchangeOnline";
			ResourceType = $null;
			resourceName = $null;
			PluginName = "Get-MonkeyEXOOutboundSpamFilterPolicy";
			ApiType = "ExoApi";
			Title = "Plugin to get information about outbound spam filter policy in Exchange Online";
			Group = @("ExchangeOnline");
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/"
		}
        #Get instance
        $Environment = $O365Object.Environment
        #Get Exchange Online Auth token
        $ExoAuth = $O365Object.auth_tokens.ExchangeOnline
	}
	process {
        $msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Exchange Online hosted outbound spam filter policy",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('ExoOutboundSpamFilterInfo');
		}
		Write-Information @msg
        $p = @{
            Authentication = $ExoAuth;
            Environment = $Environment;
            ResponseFormat = 'clixml';
            Command = 'Get-HostedOutboundSpamFilterPolicy';
            Method = "POST";
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
		$exo_outbound_spam_filter_policy = Get-PSExoAdminApiObject @p
	}
	end {
		if ($null -ne $exo_outbound_spam_filter_policy) {
			$exo_outbound_spam_filter_policy.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.OutboundSpamFilterPolicy')
			[pscustomobject]$obj = @{
				Data = $exo_outbound_spam_filter_policy;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_exo_hosted_spam_policy = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online hosted outbound spam filter policy",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('ExoOutboundSpamFilterResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}




