# PSScriptAnalyzer - ignore test file
Import-Module Pester
Set-StrictMode -Version Latest

Describe 'MonkeyJob' {
    BeforeAll {
        $Module = Get-ChildItem ("{0}/core/modules/monkeyjob" -f (Split-Path $PSScriptRoot -Parent)) -Filter '*.psm1'
        $MyModule = $Module.DirectoryName
        Import-Module $MyModule -Force
    }
    It 'Get RunspacePool' {
        $rs = New-RunspacePool
        $rs | Should -BeOfType [System.Management.Automation.Runspaces.RunspacePool]
    }
    It 'Get InitialSessionState' {
        InModuleScope monkeyjob {
            $iis = New-InitialSessionState
            $iis | Should -BeOfType [System.Management.Automation.Runspaces.InitialSessionState]
        }
    }
    It 'Run job' {
        InModuleScope monkeyjob {
            $sb = {Get-childitem -Path $_ -Force -Recurse}
            $p = @{
                ScriptBlock = $sb;
                InputObject = '.';
                Verbose= $true;
                Debug = $true;
                InformationAction = 'Continue';
            }
            Start-MonkeyJob @p
            $Job = Get-MonkeyJob
            $Job.Job | Should -BeOfType [System.Management.Automation.Job]
        }
    }
    It 'Get PowerShell' {
        InModuleScope monkeyjob {
            $sb = {Get-childitem -Path $_ -Force -Recurse}
            $p = @{
                ScriptBlock = $sb;
                InputObject = '.';
                Verbose= $true;
                Debug = $true;
                InformationAction = 'Continue';
            }
            Start-MonkeyJob @p
            $Job = Get-MonkeyJob
            $Job.Job.InnerJob | Should -BeOfType [System.Management.Automation.PowerShell]
        }
    }
    It 'Get Result' {
        InModuleScope monkeyjob {
            #Clean jobs
            Get-MonkeyJob | Remove-MonkeyJob -Force
            #Set ScriptBlock
            $sb = {return (10 / $_)}
            #Set param
            $p = @{
                ScriptBlock = $sb;
                InputObject = '2';
                Verbose= $true;
                Debug = $true;
                InformationAction = 'Continue';
            }
            #Start Job
            Start-MonkeyJob @p
            $Job = Get-MonkeyJob
            #Get result
            $Job.Task.Result | Should -Be '5'
            #Clean jobs
            Get-MonkeyJob | Remove-MonkeyJob -Force
        }
    }
    It 'Get Task' {
        InModuleScope monkeyjob {
            #Clean jobs
            Get-MonkeyJob | Remove-MonkeyJob -Force
            #Set ScriptBlock
            $sb = {return (10 / $_)}
            #Set param
            $p = @{
                ScriptBlock = $sb;
                InputObject = '2';
                Verbose= $true;
                Debug = $true;
                InformationAction = 'Continue';
            }
            #Start Job
            Start-MonkeyJob @p
            $Job = Get-MonkeyJob
            #Get result
            $Job.Task | Should -BeOfType [System.Threading.Tasks.Task]
            #Clean jobs
            Get-MonkeyJob | Remove-MonkeyJob -Force
        }
    }
}