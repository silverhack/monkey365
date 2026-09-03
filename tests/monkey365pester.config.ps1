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
    [Parameter(Mandatory = $true, HelpMessage = 'Tests Path')]
    [System.String[]]$TestPath,

    [Parameter(Mandatory = $false, HelpMessage = 'Output')]
    [System.IO.DirectoryInfo]$Output,

    [Parameter(Mandatory = $false, HelpMessage = 'CI')]
    [switch]$CI,

    [Parameter(Mandatory = $false, HelpMessage = 'Test Suite name')]
    [System.String]$TestSuiteName = "Monkey365-PowerShell-Tests",

    [parameter(Mandatory= $false, HelpMessage= "Test Output Format")]
    [ValidateSet("NUnitXml","NUnit2.5","NUnit3","JUnitXml")]
    [System.String]$TestOutputFormat = 'NUnit2.5',

    [parameter(Mandatory= $false, HelpMessage= "CI Format")]
    [ValidateSet("GithubActions","AzureDevops","Auto")]
    [System.String]$CIFormat = 'Auto',

    [parameter(Mandatory= $false, HelpMessage= "Verbosity")]
    [ValidateSet("Diagnostic","Detailed","None")]
    [System.String]$Verbosity = 'None',

    [parameter(Mandatory= $false, HelpMessage= "CI Log Level")]
    [ValidateSet("Error","Warning")]
    [System.String]$CILogLevel = 'Error',

    [Parameter(Mandatory = $false, HelpMessage = 'Code Coverage')]
    [switch]$CodeCoverage,

    [Parameter(Mandatory = $false, HelpMessage = 'Code Coverage percent target')]
    [System.Int32]$CodeCoveragePercentTarget = 45,

    [Parameter(Mandatory = $false, HelpMessage = 'Code Coverage paths')]
    [System.String[]]$CodeCoveragePath,

    [parameter(Mandatory= $false, HelpMessage= "Code Coverage Output Format")]
    [ValidateSet("JaCoCo","Cobertura")]
    [System.String]$CodeCoverageOutputFormat = 'JaCoCo',

    [Parameter(Mandatory = $false, HelpMessage = 'Include Tag')]
    [Alias('Tag')]
    [System.String[]]$IncludeTag,

    [Parameter(Mandatory = $false, HelpMessage = 'Include Tag')]
    [System.String[]]$ExcludeTag
)
Begin{
    $repoRoot = git rev-parse --show-toplevel 2>$null
    IF($null -eq $repoRoot){
        $repoRoot = Split-Path $PSScriptRoot -Parent
    }
    #Set Output Dir
    If(-not $Output){
        $PSBoundParameters['Output'] = [System.IO.DirectoryInfo]::new((Join-Path (Split-Path $PSScriptRoot -Parent) 'pester-results'))
    }
    If(-NOT $PSBoundParameters.ContainsKey('CodeCoveragePath')){
        $PSBoundParameters['CodeCoveragePath'] = Join-Path $repoRoot ("src/monkey365");
    }
    #Set output paths
    $testSuiteOutputPath = Join-Path $PSBoundParameters['Output'].FullName 'pester-results.xml'
    $codeCoverageOutputPath = Join-Path $PSBoundParameters['Output'].FullName 'coverage.xml'
}
Process{
    Try{
        # Create new configuration
        $configuration = New-PesterConfiguration
        # Run configuration
        $configuration.Run.Path = @($TestPath);
        $configuration.Run.PassThru = $true;
        $configuration.Run.TestExtension = '.Tests.ps1';
        $configuration.Run.RepoRoot = $repoRoot;
        #Apply filters
        If($IncludeTag){
            $configuration.Filter.Tag = $IncludeTag;
        }
        $configuration.Filter.ExcludeTag = $ExcludeTag;
        # Output configuration
        $configuration.Output.Verbosity = $Verbosity;
        $configuration.Output.CIFormat = $CIFormat;
        $configuration.Output.CILogLevel = $CILogLevel;
        # Test result configuration for CI artifact upload
        $configuration.TestResult.Enabled = $CI.IsPresent;
        $configuration.TestResult.OutputFormat = $TestOutputFormat;
        $configuration.TestResult.OutputPath = $testSuiteOutputPath;
        $configuration.TestResult.TestSuiteName = $TestSuiteName;
        # Code coverage configuration
        If($CodeCoverage.IsPresent) {
            $configuration.CodeCoverage.Enabled = $true
            $configuration.CodeCoverage.OutputFormat = $CodeCoverageOutputFormat
            $configuration.CodeCoverage.OutputPath = $codeCoverageOutputPath;
            $configuration.CodeCoverage.CoveragePercentTarget = $CodeCoveragePercentTarget;
            $configuration.CodeCoverage.ReportRoot = $repoRoot;
            $configuration.CodeCoverage.ExcludeTests = $true;
            #Enumerate files for code coverage
            $files = @()
            ForEach($_path in $PSBoundParameters['CodeCoveragePath']){
                $options = @{
                    Path = $_path;
                    Include = '*.ps1', '*.psm1'
                    File = $true;
                    Recurse = $true;
                }
                $files+=(Get-ChildItem @options)
            }
            $files = $files | Sort-Object -Property FullName -Unique | Select-Object -ExpandProperty FullName
            $configuration.CodeCoverage.Path = $files;
        }
        return $configuration
    }
    Catch{
        Write-Error $_.Exception.Message
    }
}
