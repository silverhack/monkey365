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

Function Get-MonkeyCSOMWebPermission{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMWebPermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding(DefaultParameterSetName = 'Current')]
    Param (
        [Parameter(Mandatory= $False, ParameterSetName = 'Web', ValueFromPipeline = $true, HelpMessage="SharePoint Site Object")]
        [Object]$Web,

        [Parameter(Mandatory= $False, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [parameter(Mandatory=$False, ParameterSetName = 'Endpoint', HelpMessage="Endpoint")]
        [String]$Endpoint,

        [parameter(Mandatory=$false, HelpMessage="Recursive search")]
        [Switch]$Recurse,

        [Parameter(Mandatory=$false, HelpMessage="Subsite depth limit recursion")]
        [int32]$Limit = 10,

        [parameter(Mandatory=$false, HelpMessage="Include lists")]
        [Switch]$IncludeLists,

        [parameter(Mandatory=$false, HelpMessage="Include lists")]
        [Switch]$IncludeItems,

        [parameter(Mandatory=$false, HelpMessage="Include lists")]
        [Switch]$ExcludeFolders,

        [Parameter(Mandatory=$false, HelpMessage="Lists to filter")]
        [string[]]$Filter,

        [Parameter(Mandatory= $false, HelpMessage="Include inherited permissions")]
        [Switch]$IncludeInheritedPermission
    )
    Begin{
        #Get permission params
        $nparams = Set-CommandParameter -Command "Get-MonkeyCSOMWebPermission" -Params $PSBoundParameters
        #Remove Recurse and limit
        [void]$nparams.Remove('Recurse')
        [void]$nparams.Remove('Limit')
        $job_params = @{
            Command = "Get-MonkeyCSOMWebPermission";
            Arguments = $nparams;
            Runspacepool = $O365Object.monkey_runspacePool;
			ReuseRunspacePool = $true;
			Debug = $O365Object.debug;
			Verbose = $O365Object.verbose;
			MaxQueue = $O365Object.MaxQueue;
			BatchSleep = $O365Object.BatchSleep;
			BatchSize = $O365Object.BatchSize;
            Throttle = $O365Object.nestedRunspaceMaxThreads;
        }
    }
    Process{
        If($PSCmdlet.ParameterSetName -eq "Current" -or $PSCmdlet.ParameterSetName -eq 'Endpoint'){
            $p = Set-CommandParameter -Command "Get-MonkeyCSOMWeb" -Params $PSBoundParameters
            #Remove recurse and limit
            [void]$p.Remove('Recurse');
            [void]$p.Remove('Limit');
            $_Web = Get-MonkeyCSOMWeb @p
            if($null -ne $_Web){
                 $_Web | Get-MonkeyCSOMWebPermission @PSBoundParameters
            }
            return
        }
        foreach($_Web in @($PSBoundParameters['Web'])){
            $objectType = $_Web | Select-Object -ExpandProperty _ObjectType_ -ErrorAction Ignore
            if ($null -ne $objectType -and $objectType -eq 'SP.Web'){
                #Get command params
                $p = Set-CommandParameter -Command "Get-MonkeyCSOMPermission" -Params $PSBoundParameters
                #Add Object
                $p.Item('Object') = $_Web
                if($PSBoundParameters.ContainsKey('IncludeInheritedPermission') -and $PSBoundParameters['IncludeInheritedPermission'].IsPresent){
                    Get-MonkeyCSOMPermission @p;
                }
                Else{
                    #Check if unique permissions
                    If($_Web | Test-HasUniqueRoleAssignment){
                        Get-MonkeyCSOMPermission @p;
                    }
                }
                #Check for lists
                if($PSBoundParameters.ContainsKey('IncludeLists') -and $PSBoundParameters['IncludeLists'].IsPresent){
                    #Get command params
                    $p = Set-CommandParameter -Command "Get-MonkeyCSOMListPermission" -Params $PSBoundParameters
                    #Add Object
                    $p.Item('Web') = $_Web
                    #Execute command
                    Get-MonkeyCSOMListPermission @p
                }
                #Check for subWebs
                if($PSBoundParameters.ContainsKey('Recurse') -and $PSBoundParameters['Recurse'].IsPresent){
                    $sWebParam = Set-CommandParameter -Command "Get-MonkeyCSOMSubWeb" -Params $PSBoundParameters
                    #Add Object
                    $sWebParam.Item('Web') = $_Web
                    #Execute jobs
                    Get-MonkeyCSOMSubWeb @sWebParam | Invoke-MonkeyJob @job_params
                    #Sleep
                    Start-Sleep -Milliseconds 500
                }
            }
            Else{
                $msg = @{
                    MessageData = ($message.SPOInvalidWebObjectMessage);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'Warning';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('MonkeyCSOMInvalidWebObject');
                }
                Write-Warning @msg
            }
        }
    }
}

