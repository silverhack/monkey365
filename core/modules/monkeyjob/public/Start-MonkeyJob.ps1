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

Function Start-MonkeyJob{
    <#
        .SYNOPSIS

        Starts a MonkeyJob using runspaces

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Start-MonkeyJob
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [cmdletbinding(DefaultParameterSetName='ScriptBlock')]
    Param (
        [Parameter(Mandatory=$True,position=0,ParameterSetName='ScriptBlock')]
        [System.Management.Automation.ScriptBlock]$ScriptBlock,

        [Parameter(Mandatory=$True, ParameterSetName = 'Command')]
        [String]$Command,

        [Parameter(Mandatory=$false, HelpMessage="arguments")]
        [Object]$Arguments,

        [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
        $InputObject,

        [Parameter(Mandatory=$false, HelpMessage="Job name")]
        [String]$JobName,

        [Parameter(HelpMessage="Variables to import into runspace")]
        [Object]$ImportVariables,

        [Parameter(HelpMessage="runspace")]
        [System.Management.Automation.Runspaces.RunspacePool]$Runspacepool,

        [Parameter(HelpMessage="modules to import into sessionState")]
        [Object]$ImportModules,

        [Parameter(HelpMessage="commands to import into sessionState")]
        [Object]$ImportCommands,

        [Parameter(HelpMessage="commands as AST to import into sessionState")]
        [Object]$ImportCommandAst,

        [Parameter(HelpMessage="Startup scripts (*ps1 files) to execute")]
        [System.Object[]]$StartUpScripts,

        [Parameter(HelpMessage="Minimum number of runspaces")]
        [ValidateRange(1,65535)]
        [int32]$MinThrottle = 1,

        [Parameter(HelpMessage="Maximum number of runspaces")]
        [ValidateRange(1,65535)]
        [int32]$Throttle = 2,

        [Parameter(HelpMessage="ApartmentState of the thread")]
        [ValidateSet("STA","MTA")]
        [String]$ApartmentState = "STA",

        [Parameter(Mandatory=$False, HelpMessage='ThrowOnRunspaceOpenError')]
        [Switch]$ThrowOnRunspaceOpenError
    )
    Begin{
        if (-not $PSBoundParameters.ContainsKey('ThrowOnRunspaceOpenError')) {
            $ThrowOnRunspaceOpenError = $False
        }
        #Create new runspace or reuse existing
        if (-not $PSBoundParameters.ContainsKey('Runspacepool')) {
            #Create a new runspacePool
            $localparams = @{
                ImportVariables = $ImportVariables;
                ImportModules = $ImportModules;
                ImportCommands = $ImportCommands;
                ImportCommandsAst = $ImportCommandAst;
                ApartmentState = $ApartmentState;
                MinThrottle = $MinThrottle;
                Throttle = $Throttle;
                StartUpScripts = $StartUpScripts;
                ThrowOnRunspaceOpenError = $ThrowOnRunspaceOpenError;
            }
            #Get runspace pool
            $Runspacepool = New-RunspacePool @localparams
            if($null -ne $Runspacepool -and $Runspacepool -is [System.Management.Automation.Runspaces.RunspacePool]){
                #Open runspace
                Write-Verbose $script:messages.OpenRunspaceMessage
                $Runspacepool.Open()
            }
        }
        else{
            if($Runspacepool.RunspacePoolStateInfo.State -eq [System.Management.Automation.Runspaces.RunspaceState]::BeforeOpen){
                #Open runspace
                Write-Verbose $script:messages.OpenRunspaceMessage
                $Runspacepool.Open()
            }
        }
        #Set Monkeyjobs variable
        $AllMonkeyJobs = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
    }
    Process{
        if($null -ne $Runspacepool -and $Runspacepool.RunspacePoolStateInfo.State -eq [System.Management.Automation.Runspaces.RunspaceState]::Opened){
            #Get scriptblock if any
            $param = @{
                RunspacePool = $Runspacepool;
                InputObject = $InputObject;
                Arguments = $Arguments;
            }
            if($PSCmdlet.ParameterSetName -eq 'ScriptBlock'){
                if($InputObject){
                    $sb = Set-ScriptBlock -ScriptBlock $ScriptBlock -AddInputObject
                }
                else{
                    $sb = Set-ScriptBlock -ScriptBlock $ScriptBlock
                }
                [void]$param.Add('ScriptBlock',$sb)
            }
            elseif($PSCmdlet.ParameterSetName -eq 'Command'){
                [void]$param.Add('Command',$Command)
            }
            #Get new PowerShell Object
            $Pipeline = New-PowerShellObject @param
            if($Pipeline){
                #Set Job name
                if($PSBoundParameters.ContainsKey('JobName') -and $PSBoundParameters['JobName']){
                    $MonkeyJobName = $PSBoundParameters['JobName'];
                }
                else{
                    $MonkeyJobName = ("MonkeyTask{0}" -f (Get-Random -Maximum 1000 -Minimum 1));
                }
                #Create a new Job
                $Job = [MonkeyJob]::new($Pipeline,$jobName);
                #Get new MonkeyJob object
                $newJob = New-MonkeyJobObject
                if($newJob -and $null -ne $Job){
                    #Populate job
                    $newJob.RunspacePoolId = $Pipeline.RunspacePool.InstanceId;
                    $newJob.Name = $MonkeyJobName;
                    $newJob.Job = $Job;
                    if($PSCmdlet.ParameterSetName -eq 'ScriptBlock'){
                        $newJob.Command = $scriptblock.ToString();
                    }
                    elseif($PSCmdlet.ParameterSetName -eq 'Command'){
                        $p = @{
                            Command = $Command;
                            InputObject = $InputObject;
                            Arguments = $Arguments;
                        }
                        $cmd = Format-Command @p
                        if($cmd){
                            $newJob.Command = $cmd.ToString();
                        }
                    }
                    #Add to list
                    [void]$AllMonkeyJobs.Add($newJob);
                }
            }
        }
        else{
            if($Runspacepool.RunspacePoolStateInfo.State -ne [System.Management.Automation.Runspaces.RunspaceState]::Opened){
                Write-Error ($script:messages.RunspaceError)
                return
            }
            else{
                Write-Error ($script:messages.UnknownError)
                return
            }
        }
    }
    End{
        try{
            for($NumJob = 0 ; $NumJob -lt $AllMonkeyJobs.Count; $NumJob++){
                $MonkeyJob = $AllMonkeyJobs.Item($NumJob)
                $MonkeyJob.Task = $MonkeyJob.Job.StartTask();
                #Add to monkeyJob var
                if($null -eq (Get-Variable -Name MonkeyJobs -ErrorAction Ignore)){
                    $MonkeyJobs = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                    [void]$MonkeyJobs.Add($MonkeyJob)
                }
                else{
                    [void]$MonkeyJobs.Add($MonkeyJob)
                }
            }
            #return jobs
            return $AllMonkeyJobs.ToArray()
        }
        catch{
            Write-Error ("MonkeyJob Error: {0}" -f $_)
        }
    }
}

