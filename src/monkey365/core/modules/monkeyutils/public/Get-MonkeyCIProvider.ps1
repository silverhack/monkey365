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

Function Get-MonkeyCIProvider {
    [CmdletBinding()]
    [OutputType([System.String])]
    param()
    # Use multiple signals to reduce accidental false positives
    #Test for GitHub
    If (
        $null -ne [Environment]::GetEnvironmentVariable('GITHUB_ACTIONS') -and `
        $null -ne [Environment]::GetEnvironmentVariable('GITHUB_RUN_ID') -and `
        $null -ne [Environment]::GetEnvironmentVariable('GITHUB_WORKFLOW')
    ) {
        return "GitHubActions"
    }
    #Test for GitLab
    If (
        $null -ne [Environment]::GetEnvironmentVariable('GITLAB_CI') -and `
        $null -ne [Environment]::GetEnvironmentVariable('CI_PIPELINE_ID') -and `
        $null -ne [Environment]::GetEnvironmentVariable('CI_JOB_ID')
    ) {
        return "GitLabCI"
    }
    #Test for Azure DevOps
    If (
        $null -ne [Environment]::GetEnvironmentVariable('TF_BUILD') -and `
        $null -ne [Environment]::GetEnvironmentVariable('BUILD_BUILDID') -and `
        $null -ne [Environment]::GetEnvironmentVariable('SYSTEM_TEAMPROJECTID')
    ) {
        return "AzurePipelines"
    }
    #Test for unknown CI
    If ($env:CI) {
        return "Unknown"
    }
    #Return none if the above fails
    return "None"
}