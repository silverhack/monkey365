# Test and analysis scripts

This directory contains the entry points used to run the Monkey365 Pester test
suite and PSScriptAnalyzer checks locally and in CI.

## Prerequisites

PowerShell 7.4 or later is recommended. The CI workflows currently use Pester
6.0.1 and PSScriptAnalyzer 1.24.0:

```powershell
Install-Module Pester -RequiredVersion 6.0.1 -Scope CurrentUser -Force
Install-Module PSScriptAnalyzer -RequiredVersion 1.24.0 -Scope CurrentUser -Force
```

Import the required module before calling its runner. For example:

```powershell
Import-Module Pester -RequiredVersion 6.0.1 -Force -ErrorAction Stop
```

## Test layout

| Path | Purpose |
| --- | --- |
| `module/` | Module import, manifest, configuration, and public API tests |
| `unit/` | Unit tests for nested modules |
| `smoke/` | Credential-free command smoke tests |
| `integration/` | Tests that can require network access or external services |

## Running Pester

`Invoke-Tests.ps1` requires at least one path through `-TestPath`. Paths are
interpreted relative to the current directory.

Run the credential-free suites from the repository root:

```powershell
./tests/Invoke-Tests.ps1 `
    -TestPath ./tests/module,./tests/unit,./tests/smoke `
    -Summary
```

Run one directory or one test file:

```powershell
./tests/Invoke-Tests.ps1 `
    -TestPath ./tests/unit/modules/monkeyhtml

./tests/Invoke-Tests.ps1 `
    -TestPath ./tests/unit/modules/monkeyhtml/New-HtmlTag.Tests.ps1 `
    -Verbosity Detailed
```

### Output directory

When `-Output` is omitted, the runner writes artifacts to `pester-results` at
the repository root. An explicitly supplied `-Output` value must be an absolute
directory path.

For example, when the current directory is `tests`:

```powershell
$outputPath = Join-Path (Split-Path $PWD -Parent) 'pester-results'

./Invoke-Tests.ps1 `
    -TestPath ./ `
    -Summary `
    -Output $outputPath `
    -CI `
    -TestSuiteName monkey365-pester `
    -CodeCoverage `
    -CodeCoveragePath ../src/monkey365/core/modules/
```

### Coverage example

Measure the `monkeyhtml` module and require 80 percent coverage:

```powershell
./tests/Invoke-Tests.ps1 `
    -TestPath ./tests/unit/modules/monkeyhtml `
    -Summary `
    -CodeCoverage `
    -CodeCoveragePath ./src/monkey365/core/modules/monkeyhtml `
    -CodeCoveragePercentTarget 80
```

### Pester parameters

| Parameter | Type | Behavior |
| --- | --- | --- |
| `-TestPath` | `string[]` | Required test files or directories. |
| `-Summary` | `switch` | Writes `pester-summary.json`. |
| `-Output` | `DirectoryInfo` | Absolute artifact directory. Defaults to the repository-level `pester-results` directory. |
| `-CI` | `switch` | Writes `pester-results.xml`. |
| `-TestSuiteName` | `string` | Suite name written to the XML and summary files. Defaults to `Monkey365-PowerShell-Tests`. |
| `-TestOutputFormat` | `string` | `NUnitXml`, `NUnit2.5`, `NUnit3`, or `JUnitXml`. Defaults to `NUnit2.5`. |
| `-CIFormat` | `string` | `GithubActions`, `AzureDevops`, or `Auto`. Defaults to `Auto`. |
| `-Verbosity` | `string` | `Diagnostic`, `Detailed`, or `None`. Defaults to `None`. |
| `-CILogLevel` | `string` | CI annotation level: `Error` or `Warning`. Defaults to `Error`. |
| `-CodeCoverage` | `switch` | Collects coverage and writes `coverage.xml`. |
| `-CodeCoveragePercentTarget` | `int` | Minimum coverage percentage. Defaults to 45. |
| `-CodeCoveragePath` | `string[]` | Source directories to instrument. Defaults to `src/monkey365`. |
| `-CodeCoverageOutputFormat` | `string` | `JaCoCo` or `Cobertura`. Defaults to `JaCoCo`. |
| `-IncludeTag` | `string[]` | Includes tests with any matching tag. `-Tag` is an alias. |
| `-ExcludeTag` | `string[]` | Excludes tests with any matching tag. |

### Pester artifacts and exit codes

| Artifact | Written when |
| --- | --- |
| `pester-failures.json` | Pester returns a result object |
| `pester-summary.json` | `-Summary` is specified |
| `pester-results.xml` | `-CI` is specified |
| `coverage.xml` | `-CodeCoverage` is specified |

`pester-failures.json` contains `TestName`, `FilePath`, `ErrorMessage`, and
`StackTrace` for each failed test. The summary contains test counts, duration,
suite name, Pester version, and coverage data when coverage is enabled.

| Pester result | Exit code |
| --- | --- |
| Passed | 0 |
| Failed | 1 |

`-CI` enables `pester-results.xml`; it does not change the exit code.

## PSScriptAnalyzer

Required parameters: `-Path` and `-ModuleName`.

### Repository scan used by CI

```powershell
./tests/Invoke-Analyzer.ps1 `
    -Path ./src/monkey365 `
    -Recurse `
    -OutputFormat SARIF `
    -ModuleName monkey365 `
    -Output ./logs/PSScriptAnalyzer.sarif `
    -FailOnSeverity Error `
    -Force
```

### Output path rules

| Script | `-Output` value |
| --- | --- |
| `Invoke-Tests.ps1` | Absolute directory path |
| `Invoke-Analyzer.ps1` | File path; relative values start at the repository root |

`-Force` is required when the analyzer output file already exists.

### Analyzer parameters

| Parameter | Type | Behavior |
| --- | --- | --- |
| `-Path` | `string[]` | Required source directories. |
| `-ModuleName` | `string` | Required suite name for NUnit output and automation identifier for SARIF output. |
| `-Recurse` | `switch` | Recursively scans each source directory. |
| `-TreatSuppressedAsSkipped` | `switch` | Represents fully suppressed rules as skipped NUnit cases. |
| `-Output` | `string` | Destination file used with `-OutputFormat`; relative paths are repository-relative. |
| `-Force` | `switch` | Replaces an existing output file. |
| `-OutputFormat` | `string[]` | Artifact format. Specify one value: `Nunit` or `SARIF`. |
| `-Severity` | `string[]` | Collects `Error`, `Warning`, and/or `Information` diagnostics. |
| `-FailOnSeverity` | `string[]` | Selects the severities that fail the quality gate. |
| `-IncludeRule` | `string[]` | Runs only the named analyzer rules. |
| `-ExcludeRule` | `string[]` | Excludes the named analyzer rules. |

The analyzer checks `.ps1`, `.psm1`, and `.psd1` files. It skips files ending
in `Tests.ps1`.

### Return values and exit codes

| Arguments | Result |
| --- | --- |
| No `-OutputFormat` | PowerShell diagnostic objects |
| `-OutputFormat` without `-Output` | NUnit or SARIF text |
| `-OutputFormat` with `-Output` | A file, followed by the `-FailOnSeverity` check |

The first two forms return data to the caller. The third form is intended for
CI and returns exit code 1 when a diagnostic matches `-FailOnSeverity`.

## GitHub Actions

Monkey365 keeps Pester and PSScriptAnalyzer in separate workflows:

- [Pester tests](../.github/workflows/pester.yml)
- [PSScriptAnalyzer](../.github/workflows/psscriptanalyzer.yml)

The Pester workflow derives its artifact directory from `GITHUB_WORKSPACE` so
that `-Output` receives a full path. Keep that conversion if the workflow is
moved or split into additional jobs.
