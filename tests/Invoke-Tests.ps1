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

<#
.SYNOPSIS
Runs the Monkey365 Pester 6.x test suite and writes structured test artifacts.

.DESCRIPTION
Loads tests/monkey365pester.config.ps1, applies command-line overrides, runs
Pester, and writes a JSON failure report. The optional summary report, NUnit
XML, and coverage XML are enabled with -Summary, -CI, and -CodeCoverage.
The script exits with code 1 when tests fail and 0 when they pass.

.PARAMETER TestPath
One or more test files or directories. This parameter is required.

.PARAMETER Summary
Writes pester-summary.json to the output directory.

.PARAMETER Output
Directory for JSON, NUnit, and code coverage artifacts. The default is the
repository-level pester-results directory.

.PARAMETER CI
Enables test-result XML output.

.PARAMETER TestSuiteName
Suite name written to the test-result XML and JSON summary.

.PARAMETER TestOutputFormat
Test-result XML format: NUnitXml, NUnit2.5, NUnit3, or JUnitXml.

.PARAMETER CIFormat
Pester CI log format: GithubActions, AzureDevops, or Auto.

.PARAMETER Verbosity
Pester output verbosity: Diagnostic, Detailed, or None.

.PARAMETER CILogLevel
Pester CI annotation level: Error or Warning.

.PARAMETER CodeCoverage
Enables code coverage output and evaluates the configured coverage floor.

.PARAMETER CodeCoveragePercentTarget
Minimum coverage percentage. The default is 45.

.PARAMETER CodeCoveragePath
One or more source directories to include. The default is src/monkey365.

.PARAMETER CodeCoverageOutputFormat
Coverage output format: JaCoCo or Cobertura.

.PARAMETER IncludeTag
Runs tests carrying at least one supplied tag. Tag is an alias for IncludeTag.

.PARAMETER ExcludeTag
Excludes tests carrying any supplied tag.

.EXAMPLE
./tests/Invoke-Tests.ps1 -TestPath ./tests/module,./tests/unit,./tests/smoke -Summary

.EXAMPLE
./tests/Invoke-Tests.ps1 -TestPath ./tests/unit -Output ./pester-results `
    -CI -TestSuiteName monkey365-pester

.EXAMPLE
./tests/Invoke-Tests.ps1 -TestPath ./tests/unit/modules/monkeyhtml `
    -Summary -CodeCoverage `
    -CodeCoveragePath ./src/monkey365/core/modules/monkeyhtml `
    -CodeCoveragePercentTarget 80
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = 'Tests Path')]
    [System.String[]]$TestPath,

    [Parameter(Mandatory = $false, HelpMessage = 'Generate Pester Summary file')]
    [switch]$Summary,

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

    [Parameter(Mandatory = $false, HelpMessage = 'Exclude Tag')]
    [System.String[]]$ExcludeTag
)
Begin{
    $configuration = $results = $null;
    $allTests = [System.Collections.Generic.List[PsObject]]::new()
    #Set Output Dir
    If(-not $Output){
        $PSBoundParameters['Output'] = [System.IO.DirectoryInfo]::new((Join-Path (Split-Path $PSScriptRoot -Parent) 'pester-results'))
    }
    #Create directory if does not exists
    [void][System.IO.Directory]::CreateDirectory($PSBoundParameters['Output'])
    #Set summary and failure paths
    $summaryOutputPath = Join-Path $PSBoundParameters['Output'].FullName 'pester-summary.json'
    $failureOutputPath = Join-Path $PSBoundParameters['Output'].FullName 'pester-failures.json'
    #Set empty file
    [System.IO.File]::WriteAllText($failureOutputPath, '{}', [System.Text.UTF8Encoding]::new($false))
    #Get repository root
    $repoRoot = git rev-parse --show-toplevel 2>$null
    IF($null -eq $repoRoot){
        $repoRoot = Split-Path $PSScriptRoot -Parent
    }
    $resolvedPaths = @($TestPath | ForEach-Object {
        If (-not (Test-Path $_)) {
            Write-Warning "Test path not found: $_"
        }
        $_
    });
    If($resolvedPaths.Count -gt 0){
        $PSBoundParameters['TestPath'] = $resolvedPaths;
        $pesterConfig = [System.IO.Path]::Combine($repoRoot, "tests", "monkey365pester.config.ps1")
        $monkey365pester = Get-Command -Name $pesterConfig -CommandType ExternalScript -ErrorAction Ignore
        If($null -ne $monkey365pester){
            #Set parameters
            $newPsboundParams = [ordered]@{}
            $param = $monkey365pester.Parameters.Keys
            ForEach($p in $param.GetEnumerator()){
                If($PSBoundParameters.ContainsKey($p)){
                    $newPsboundParams.Add($p,$PSBoundParameters[$p])
                }
            }
        }
        Else{
            Write-Error ("Function monkey365pester.config.ps1 was not found")
            return
        }
        $configuration = & $pesterConfig @newPsboundParams
        #Ensure PassThru is enabled
        $configuration.Run.PassThru = $true
    }
}
Process{
    Try{
        $start = [System.DateTimeOffset]::UtcNow
        $pesterAnalyzer = Get-Module -Name Pester -ErrorAction Ignore
        If($null -eq $pesterAnalyzer){
            throw "Pester is not present"
        }
        If($null -ne $configuration){
            $results = Invoke-Pester -Configuration $configuration
        }
        If($null -ne $results){
            ForEach($test in $results.Failed.GetEnumerator()){
                $testObj = [PsCustomObject][ordered]@{
                    TestName = $test.ExpandedName;
                    FilePath = $test.ScriptBlock.File;
                    ErrorMessage = ($test.ErrorRecord | ForEach-Object { $_.Exception.Message }) -join "`n";
                    StackTrace = ($test.ErrorRecord | ForEach-Object { $_.ScriptStackTrace }) -join "`n";
                }
                #Add to array
                [void]$allTests.Add($testObj);
            }
            #Save failures
            #Convert failures to JSON and save file
            $failuresText = $allTests | ConvertTo-Json -Depth 5
            [System.IO.File]::WriteAllText($failureOutputPath, $failuresText, [System.Text.UTF8Encoding]::new($false))
            Write-Information "Pester failures results: $($failureOutputPath)" -InformationAction Continue
            #Add summary
            If($PsBoundParameters.ContainsKey('Summary') -and $PSBoundParameters['Summary'].IsPresent){
                #Set empty file
                '{}' | Out-File -FilePath $summaryOutputPath -Encoding utf8
                #Get Summary
                $summaryObj = [ordered]@{
                    SchemaVersion         = '1.0'
                    TestSuiteName         = $TestSuiteName;
                    Result                = $results.Result;
                    PassedCount           = $results.PassedCount;
                    FailedCount           = $results.FailedCount;
                    SkippedCount          = $results.SkippedCount;
                    InconclusiveCount     = $results.InconclusiveCount;
                    NotRunCount           = $results.NotRunCount;
                    TotalCount            = $results.TotalCount;
                    FailedBlocksCount     = $results.FailedBlocksCount;
                    FailedContainersCount = $results.FailedContainersCount;
                    Duration              = $results.Duration.ToString('c');
                    DurationSeconds       = [math]::Round($results.Duration.TotalSeconds, 3);
                    ExecutedAtUtc         = $start.ToString('o');
                    PesterVersion         = $results.Version.ToString()
                }
                #Set coverage data
                $coverageTarget = $configuration.CodeCoverage.CoveragePercentTarget.Value;
                If ($CodeCoverage -and $null -ne $results.CodeCoverage){
                    $summaryObj['CoveragePercent'] = [math]::Round([double]$results.CodeCoverage.CoveragePercent, 2)
                    If($null -ne $coverageTarget){
                        $summaryObj['CoverageTarget'] = [math]::Round([double]$coverageTarget, 2);
                    }
                }
                #Convert summary to JSON and save file
                $summaryText = $summaryObj | ConvertTo-Json -Depth 3
                [System.IO.File]::WriteAllText($summaryOutputPath, $summaryText, [System.Text.UTF8Encoding]::new($false))
                Write-Information "Pester summary results: $($summaryOutputPath)" -InformationAction Continue
            }
            If($results.FailedCount -gt 0) {
                $msgObject = [System.Management.Automation.HostInformationMessage]@{
                    Message = ("{0} test(s) failed. See {1} and {2}" -f $results.FailedCount, $summaryOutputPath, $failureOutputPath)
                    ForegroundColor = [System.ConsoleColor]::Red
                }
                Write-Information -MessageData $msgObject -InformationAction Continue
                exit 1
            }
            Else{
                $msgObject = [System.Management.Automation.HostInformationMessage]@{
                    Message = ("All {0} tests passed." -f $results.PassedCount)
                    ForegroundColor = [System.ConsoleColor]::Green
                }
                Write-Information -MessageData $msgObject -InformationAction Continue
                exit 0
            }
        }
    }
    Catch{
        Write-Error $_.Exception.Message
    }
}
