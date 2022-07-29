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


Function Get-MonkeyEXOUsersMailbox{
    <#
        .SYNOPSIS
		Plugin to get information about mailboxes in Exchange Online

        .DESCRIPTION
		Plugin to get information about mailboxes in Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXOUsersMailbox
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory= $false, HelpMessage="Background Plugin ID")]
        [String]$pluginId
    )
    Begin{
        #create array
        $mailbox_permissions = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
        #Getting environment
        $Environment = $O365Object.Environment
        #Get EXO authentication
        $exo_auth = $O365Object.auth_tokens.ExchangeOnline
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Exchange Online Mailboxes", $O365Object.TenantID);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('ExoMailboxesInfo');
        }
        Write-Information @msg
        #Get Mailboxes
        $param = @{
            Authentication = $exo_auth;
            Environment = $Environment;
            ObjectType = "Mailbox";
            extraParameters = "PropertySet=All";
        }
        $mailBoxes = Get-PSExoAdminApiObject @param
        if($mailboxes){
            #Get mailbox Forwarding
            $forwarding_mailboxes = $mailboxes | Select-Object UserPrincipalName,ForwardingSmtpAddress,DeliverToMailboxAndForward
            #Getting mailbox permissions
            #Generate vars
            $vars = @{
                "O365Object"=$O365Object;
                "WriteLog"=$WriteLog;
                'Verbosity' = $Verbosity;
                'InformationAction' = $InformationAction;
            }
            $param = @{
                ScriptBlock = {Get-PSExoMailBoxPermission -mailBox $_};
                ImportCommands = $O365Object.LibUtils;
                ImportVariables = $vars;
                ImportModules = $O365Object.runspaces_modules;
                StartUpScripts = $O365Object.runspace_init;
                ThrowOnRunspaceOpenError = $true;
                Debug = $O365Object.VerboseOptions.Debug;
                Verbose = $O365Object.VerboseOptions.Verbose;
                Throttle = $O365Object.nestedRunspaceMaxThreads;
                MaxQueue = $O365Object.MaxQueue;
                BatchSleep = $O365Object.BatchSleep;
                BatchSize = $O365Object.BatchSize;
            }
            #Get objects
            $mailbox_permissions = $mailboxes | Invoke-MonkeyJob @param
        }
    }
    End{
        if($mailboxes){
            $mailboxes.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.Mailboxes')
            [pscustomobject]$obj = @{
                Data = $mailboxes
            }
            $returnData.o365_exo_mailboxes = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online mailboxes", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('ExoMailboxesEmptyResponse');
            }
            Write-Warning @msg
        }
        if($forwarding_mailboxes){
            $forwarding_mailboxes.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.ForwardingMailboxes')
            [pscustomobject]$obj = @{
                Data = $forwarding_mailboxes
            }
            $returnData.o365_exo_mailbox_forwarding = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online mailbox forwarding", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('ExoMailboxesEmptyResponse');
            }
            Write-Warning @msg
        }
        if($mailbox_permissions){
            $mailbox_permissions.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.MailboxPermissions')
            [pscustomobject]$obj = @{
                Data = $mailbox_permissions
            }
            $returnData.o365_exo_mailbox_permissions = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online mailbox permissions", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('ExoMailboxesEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
