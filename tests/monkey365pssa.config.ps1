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

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = 'Path')]
    [System.String[]]$Path,

    [Parameter(Mandatory = $true, HelpMessage = 'Module Name')]
    [System.String]$ModuleName,

    [Parameter(Mandatory = $false, HelpMessage = 'Treat Suppressed rules as Skipped')]
    [Switch]$TreatSuppressedAsSkipped,

    [Parameter(Mandatory = $false, HelpMessage = 'Recurse')]
    [switch]$Recurse,

    [Parameter(Mandatory = $false, HelpMessage = 'Output')]
    [System.String]$Output,

    [Parameter(Mandatory = $false, HelpMessage = 'NUnit Export')]
    [switch]$CI,

    [Parameter(Mandatory = $false, HelpMessage = 'Severity')]
    [ValidateSet('Error', 'Warning', 'Information')]
    [System.String[]]$Severity,

    [Parameter(Mandatory = $false, HelpMessage = 'Fail on Severity')]
    [ValidateSet('Error', 'Warning', 'Information')]
    [System.String[]]$FailOnSeverity,

    [Parameter(Mandatory = $false, HelpMessage = 'Include Default Rules')]
    [switch]$DefaultRules = $true,

    [Parameter(Mandatory = $false, HelpMessage = 'Include rule')]
    [System.String[]]$IncludeRule,

    [Parameter(Mandatory = $false, HelpMessage = 'Exclude rule')]
    [System.String[]]$ExcludeRule
)

$repoRoot = git rev-parse --show-toplevel 2>$null
IF($null -eq $repoRoot){
    $repoRoot = Split-Path $PSScriptRoot -Parent
}

#Set Output Dir
If(-not $Output){
    $outputPath = $jsonOutput = $summaryJsonOutput = $null
}
Else{
    If (-NOT [System.IO.Path]::IsPathRooted($PSBoundParameters['Output'])) {
        $PSBoundParameters['Output'] = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $PSBoundParameters['Output']));
    }
    $outputPath = [System.IO.Path]::GetDirectoryName($PSBoundParameters['Output']);
    #$fileName = [System.IO.Path]::GetFileName($PSBoundParameters['Output']);
    $jsonOutput = Join-Path $outputPath ('{0}-results.json' -f [System.IO.Path]::GetFileNameWithoutExtension($PSBoundParameters['Output']))
    $summaryJsonOutput = Join-Path $outputPath ('{0}-summary.json' -f [System.IO.Path]::GetFileNameWithoutExtension($PSBoundParameters['Output']))
    #Create directory if does not exists
    [void][System.IO.Directory]::CreateDirectory($outputPath);
}

# These are the repository-wide PSScriptAnalyzer defaults. Keep rule exclusions
# narrow and document why a rule cannot be applied globally before adding it.
$analyzerSettings = @{
    Severity     = @('Error', 'Warning')
    IncludeRules = @()
    ExcludeRules = @()
    Rules        = @{}
}

$blockingSeverities = @('Error')

If($PSBoundParameters.ContainsKey('Severity')){
    $analyzerSettings.Severity = $Severity
}
If($PSBoundParameters.ContainsKey('IncludeRule')){
    $analyzerSettings.IncludeRules = $IncludeRule
}
If($PSBoundParameters.ContainsKey('ExcludeRule')){
    $analyzerSettings.ExcludeRules = $ExcludeRule
}
If($PSBoundParameters.ContainsKey('FailOnSeverity')){
    $blockingSeverities = $FailOnSeverity
}

[PsCustomObject][ordered]@{
    SchemaVersion  = '1.0';
    RepositoryRoot = $repoRoot;
    ModuleName     = $ModuleName;
    Run            = [PsCustomObject][ordered]@{
        Path                    = $Path;
        Recurse                 = [Bool]$Recurse;
        DefaultRules            = [Bool]$DefaultRules;
    }
    AnalyzerSettings = $analyzerSettings
    QualityGate = [PsCustomObject][ordered]@{
        FailOnSeverity = $blockingSeverities
    }
    Output = [PsCustomObject][ordered]@{
        Directory  = $outputPath;
        Json        = $jsonOutput ;
        SummaryJson = $summaryJsonOutput;
        NUnit       = [pscustomobject][ordered]@{
            Enabled = [Bool]$CI;
            Path    = $PSBoundParameters['Output'];
        }
    }
}
