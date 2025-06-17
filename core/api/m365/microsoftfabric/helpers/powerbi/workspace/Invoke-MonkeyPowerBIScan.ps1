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
# See the License for the specIfic language governing permissions and
# limitations under the License.

Function Invoke-MonkeyPowerBiScan{
    <#
        .SYNOPSIS
        Plugin to scan PowerBI workspaces

        .DESCRIPTION
        Plugin to scan PowerBI workspaces

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-MonkeyPowerBiScan
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param()
    Begin{
        #set vars
        $workspaceids = $null
        $sliced_workspaces = [System.Collections.Generic.List[System.Object]]::new()
        $started_scans = [System.Collections.Generic.List[System.Object]]::new()
        $ws_scan_results = [System.Collections.Generic.List[System.Object]]::new()
        $scan_uri = '/workspaces/getInfo?lineage=True&datasourceDetails=True&datasetSchema=True&datasetExpressions=True&getArtIfactUsers=True'
        $scan_status_uri = '/workspaces/scanStatus/'
        $scan_results_uri = '/workspaces/scanResult/'
        #Getting environment
        $Environment = $O365Object.Environment
        #Get PowerBI Access Token
		$access_token = $O365Object.auth_tokens.PowerBI
        $msg = @{
            MessageData = "Getting PowerBI workspaces";
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $script:InformationAction;
            Tags = @('PowerBIWorkspacesInfo');
        }
        Write-Information @msg
        #Getting Workspace ids
        $p = @{
            Authentication = $access_token;
            ObjectType = 'workspaces/modIfied';
            Scope = 'Organization';
            Environment = $Environment;
            Method = "GET";
            APIVersion = 'v1.0';
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
            InformationAction = $O365Object.InformationAction;
        }
        $workspaces = Get-MonkeyPowerBIObject @p
        If($null -ne $workspaces){
            #Get Workspace Ids
            $workspaceids = $workspaces | Select-Object -ExpandProperty id
        }
        If($null -ne $workspaceids){
            #Get sliced workspaces to avoid 100 limit in PowerBI
            $workspaceids | Split-Array -Elements 100 | ForEach-Object {
                $d = @{
                    workspaces = @(
                        $_
                    )
                } | ConvertTo-Json
                $sliced_workspaces.Add($d)
            }
        }
    }
    Process{
        If($sliced_workspaces.Count -gt 0){
            ForEach($sq in $sliced_workspaces){
                $msg = @{
                    MessageData = ("Getting metadata from workspace(s)");
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Tags = @('PowerBIWorkspacesInfo');
                }
                Write-Verbose @msg
                $p = @{
                    Authentication = $access_token;
                    ObjectType = $scan_uri;
                    Scope = 'Organization';
                    Environment = $Environment;
                    Data = $sq;
                    Method = "POST";
                    APIVersion = 'v1.0';
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
                }
                $scan_result = Get-MonkeyPowerBIObject @p
                If($null -ne $scan_result -and $null -ne $scan_result.PsObject.Properties.Item('id')){
                    [void]$started_scans.Add($scan_result.id)
                }
            }
        }
        #Get status for scans
        If($started_scans.Count -gt 0){
            ForEach($scan in $started_scans){
                $uri_status = ("{0}{1}" -f $scan_status_uri,$scan)
                $msg = @{
                    MessageData = ("Checking status of {0} scan" -f $scan);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    Verbose = $O365Object.verbose;
                    Tags = @('PowerBIScanStatusInfo');
                }
                Write-Verbose @msg
                do {
                    $p = @{
                        Authentication = $access_token;
                        ObjectType = $uri_status;
                        Scope = 'Organization';
                        Environment = $Environment;
                        Method = "GET";
                        APIVersion = 'v1.0';
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
                    }
                    $status = Get-MonkeyPowerBIObject @p
                    Start-Sleep -Seconds 3
                }
                while ($null -ne $status -and $null -ne $status.PsObject.Properties.Item('status') -and $status.status -ne "Succeeded")
            }
        }
        #Getting results from scans
        If($started_scans.Count -gt 0){
            ForEach($scan in $started_scans){
                $uri_result = ("{0}{1}" -f $scan_results_uri,$scan)
                $msg = @{
                    MessageData = ("Getting results from {0} scan" -f $scan);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    Verbose = $O365Object.verbose;
                    Tags = @('PowerBIScanResults');
                }
                Write-Verbose @msg
                $p = @{
                    Authentication = $access_token;
                    ObjectType = $uri_result;
                    Scope = 'Organization';
                    Environment = $Environment;
                    Method = "GET";
                    APIVersion = 'v1.0';
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
                }
                $scan_result = Get-MonkeyPowerBIObject @p
                If($null -ne $scan_result -and $null -ne $scan_result.PsObject.Properties.Item('workspaces')){
                    [void]$ws_scan_results.Add($scan_result.workspaces)
                }
            }
        }
    }
    End{
        #Return object
        $ws_scan_results
    }
}

