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

function Merge-HashTable {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Merge-HashTable
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    param(
        [hashtable] $default, # Your original set
        [hashtable] $uppend # The set you want to update/append to the original set
    )

    # Clone for idempotence
    $default1 = $default.Clone();

    # We need to remove any key-value pairs in $default1 that we will
    # be replacing with key-value pairs from $uppend
    foreach ($key in $uppend.Keys) {
        if ($default1.ContainsKey($key)) {
            $default1.Remove($key);
        }
    }

    # Union both sets
    return $default1 + $uppend;
}


