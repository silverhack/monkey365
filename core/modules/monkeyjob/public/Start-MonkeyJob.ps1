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

        [Parameter(Mandatory=$True,Position = 0, ParameterSetName = 'Command')]
        [String]$Command,

        [Parameter(Mandatory = $True, Position = 0, ParameterSetName = 'FilePath', HelpMessage = 'PowerShell Script file')]
        [ValidateScript(
            {
            if( -Not ($_ | Test-Path) ){
                throw ("The PowerShell file does not exist in {0}" -f (Split-Path -Path $_))
            }
            if(-Not ($_ | Test-Path -PathType Leaf) ){
                throw "The argument must be a ps1 file. Folder paths are not allowed."
            }
            if($_ -notmatch "(\.ps1)"){
                throw "The script specified argument must be of type ps1"
            }
            return $true
        })]
        [System.IO.FileInfo]$File,

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
        #Set null
        $Pipeline = $monkeyJob = $Job = $null;
        #Add runspaceOpenError var
        If (-not $PSBoundParameters.ContainsKey('ThrowOnRunspaceOpenError')) {
            $ThrowOnRunspaceOpenError = $False
        }
        $Verbose = $False;
        $Debug = $False;
        $InformationAction = 'SilentlyContinue'
        If($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters.Verbose){
            $Verbose = $True
        }
        If($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters.Debug){
            $DebugPreference = 'Continue'
            $Debug = $True
        }
        If($PSBoundParameters.ContainsKey('InformationAction')){
            $InformationAction = $PSBoundParameters['InformationAction']
        }
        #Create new runspace or reuse existing
        If (-not $PSBoundParameters.ContainsKey('Runspacepool')) {
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
                Verbose = $Verbose;
                Debug = $Debug;
                InformationAction = $InformationAction;
            }
            #Get runspace pool
            $Runspacepool = New-RunspacePool @localparams
            If($null -ne $Runspacepool -and $Runspacepool -is [System.Management.Automation.Runspaces.RunspacePool]){
                #Open runspace
                Write-Verbose $script:messages.OpenRunspaceMessage
                $Runspacepool.Open()
            }
        }
        Else{
            if($Runspacepool.RunspacePoolStateInfo.State -eq [System.Management.Automation.Runspaces.RunspaceState]::BeforeOpen){
                #Open runspace
                Write-Verbose $script:messages.OpenRunspaceMessage
                $Runspacepool.Open()
            }
        }
    }
    Process{
        If($null -ne $Runspacepool -and $Runspacepool.RunspacePoolStateInfo.State -eq [System.Management.Automation.Runspaces.RunspaceState]::Opened){
            #Get PowerShell Param
            $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Get-PowerShellParam")
            $newPsboundParams = @{}
            If($null -ne $MetaData){
                $param = $MetaData.Parameters.Keys
                ForEach($p in $param.GetEnumerator()){
                    If($PSBoundParameters.ContainsKey($p)){
                        $newPsboundParams.Add($p,$PSBoundParameters[$p])
                    }
                }
            }
            #Check if RunspacePool
            If(-NOT $newPsboundParams.ContainsKey('RunspacePool')){
                [void]$newPsboundParams.Add('RunspacePool',$Runspacepool);
            }
            $psParams = Get-PowerShellParam @newPsboundParams
            If($null -ne $psParams){
                $Pipeline = New-PowerShellObject @psParams
            }
            If($null -ne $Pipeline){
                #Get Command Name
                $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Format-CommandName")
                $newPsboundParams = [ordered]@{}
                If($null -ne $MetaData){
                    $param = $MetaData.Parameters.Keys
                    ForEach($p in $param.GetEnumerator()){
                        If($PSBoundParameters.ContainsKey($p)){
                            $newPsboundParams.Add($p,$PSBoundParameters[$p])
                        }
                    }
                }
                $commandName = Format-CommandName @newPsboundParams
                #Set new Job object
                $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "New-MonkeyJobObject")
                $jobObjectParams = [ordered]@{}
                If($null -ne $MetaData){
                    $param = $MetaData.Parameters.Keys
                    ForEach($p in $param.GetEnumerator()){
                        If($PSBoundParameters.ContainsKey($p)){
                            $jobObjectParams.Add($p,$PSBoundParameters[$p])
                        }
                    }
                }
                #Get new MonkeyJob object
                $monkeyJob = New-MonkeyJobObject @jobObjectParams -CommandName $commandName
                IF($null -ne $monkeyJob){
                    #Create a new Job
                    $Job = [MonkeyJob]::new($Pipeline,$monkeyJob.Name);
                }
            }
            If($null -ne $Job){
                #Populate job
                $monkeyJob.RunspacePoolId = $Pipeline.RunspacePool.InstanceId;
                $monkeyJob.Job = $Job;
                #Start task
                $monkeyJob.Task = $monkeyJob.Job.StartTask();
                #Add to monkeyJob var
                [void]$Script:MonkeyJobs.Add($monkeyJob)
                #return Job
                $monkeyJob
            }
        }
        Else{
            If($Runspacepool.RunspacePoolStateInfo.State -ne [System.Management.Automation.Runspaces.RunspaceState]::Opened){
                Write-Error ($script:messages.RunspaceError)
                return
            }
            Else{
                Write-Error ($script:messages.UnknownError)
                return
            }
        }
    }
    End{
        #Nothing to do here
    }
}
