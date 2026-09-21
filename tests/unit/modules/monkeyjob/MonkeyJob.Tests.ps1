Set-StrictMode -Version Latest

Describe 'MonkeyJob runspace primitives' {
    BeforeAll {
        $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
        Import-Module (Join-Path $script:repoRoot 'src\monkey365\core\modules\monkeyjob') -Force -ErrorAction Stop
    }

    It 'creates a runspace pool' {
        $pool = New-RunspacePool
        try {
            $pool | Should -BeOfType [System.Management.Automation.Runspaces.RunspacePool]
        }
        finally {
            $pool.Close()
            $pool.Dispose()
        }
    }

    It 'creates an initial session state' {
        InModuleScope monkeyjob {
            New-InitialSessionState |
                Should -BeOfType [System.Management.Automation.Runspaces.InitialSessionState]
        }
    }

    AfterAll {
        Remove-Module monkeyjob -Force -ErrorAction Ignore
    }
}
