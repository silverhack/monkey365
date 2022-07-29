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

Function New-HumanGuid{
    <#
        .SYNOPSIS
        A human readable hash function
        .DESCRIPTION
        A human readable hash function
        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-HumanGuid
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [cmdletbinding()]
    [OutputType([System.String])]
    Param (
        [parameter(Mandatory=$false, HelpMessage='Default 4')]
        [int32]$words = 4,

        [parameter(Mandatory=$false, HelpMessage='String separator. Default -')]
        [String]$separator = '-'
    )
    Begin{
        $encoding = [System.Text.Encoding]::UTF8
        $random_key = -join (1..256 | ForEach {[char]((33..126) | Get-Random)})
        $xorkey = $encoding.GetBytes($random_key)
        $human_array = New-Object System.Collections.Generic.List[System.String]
        $output = [String]::Empty
        $default_wordlist = @(
            'ack', 'alabama', 'alanine', 'alaska', 'alpha', 'angel', 'apart', 'april',
            'arizona', 'arkansas', 'artist', 'asparagus', 'aspen', 'august', 'autumn',
            'avocado', 'bacon', 'bakerloo', 'batman', 'beer', 'berlin', 'beryllium',
            'black', 'blossom', 'blue', 'bluebird', 'bravo', 'bulldog', 'burger',
            'butter', 'california', 'carbon', 'cardinal', 'carolina', 'carpet', 'cat',
            'ceiling', 'charlie', 'chicken', 'coffee', 'cola', 'cold', 'colorado',
            'comet', 'connecticut', 'crazy', 'cup', 'dakota', 'december', 'delaware',
            'delta', 'diet', 'don', 'double', 'early', 'earth', 'east', 'echo',
            'edward', 'eight', 'eighteen', 'eleven', 'emma', 'enemy', 'equal',
            'failed', 'fanta', 'fifteen', 'fillet', 'finch', 'fish', 'five', 'fix',
            'floor', 'florida', 'football', 'four', 'fourteen', 'foxtrot', 'freddie',
            'friend', 'fruit', 'gee', 'georgia', 'glucose', 'golf', 'green', 'grey',
            'hamper', 'happy', 'harry', 'hawaii', 'helium', 'high', 'hot', 'hotel',
            'hydrogen', 'idaho', 'illinois', 'india', 'indigo', 'ink', 'iowa',
            'island', 'item', 'jersey', 'jig', 'johnny', 'juliet', 'july', 'jupiter',
            'kansas', 'kentucky', 'kilo', 'king', 'kitten', 'lactose', 'lake', 'lamp',
            'lemon', 'leopard', 'lima', 'lion', 'lithium', 'london', 'louisiana',
            'low', 'magazine', 'magnesium', 'maine', 'mango', 'march', 'mars',
            'maryland', 'massachusetts', 'may', 'mexico', 'michigan', 'mike',
            'minnesota', 'mirror', 'mississippi', 'missouri', 'mobile', 'mockingbird',
            'monkey', 'montana', 'moon', 'mountain', 'muppet', 'music', 'nebraska',
            'neptune', 'network', 'nevada', 'nine', 'nineteen', 'nitrogen', 'north',
            'november', 'nuts', 'october', 'ohio', 'oklahoma', 'one', 'orange',
            'oranges', 'oregon', 'oscar', 'oven', 'oxygen', 'papa', 'paris', 'pasta',
            'pennsylvania', 'pip', 'pizza', 'pluto', 'potato', 'princess', 'purple',
            'quebec', 'queen', 'quiet', 'red', 'river', 'robert', 'robin', 'romeo',
            'rugby', 'sad', 'salami', 'saturn', 'september', 'seven', 'seventeen',
            'shade', 'sierra', 'single', 'sink', 'six', 'sixteen', 'skylark', 'snake',
            'social', 'sodium', 'solar', 'south', 'spaghetti', 'speaker', 'spring',
            'stairway', 'steak', 'stream', 'summer', 'sweet', 'table', 'tango', 'ten',
            'tennessee', 'tennis', 'texas', 'thirteen', 'three', 'timing', 'triple',
            'twelve', 'twenty', 'two', 'uncle', 'united', 'uniform', 'uranus', 'utah',
            'vegan', 'venus', 'vermont', 'victor', 'video', 'violet', 'virginia',
            'washington', 'west', 'whiskey', 'white', 'william', 'winner', 'winter',
            'wisconsin', 'wolfram', 'wyoming', 'xray', 'yankee', 'yellow', 'zebra',
            'zulu'
        )
        #Get UUID
        $UUID = ([system.guid]::NewGuid()).ToString().Replace('-','')
        $out = @()
        for ($i = 0; $i -lt $UUID.Length; $i++) {
            $out += [char]([Byte]$UUID[$i] -bxor [Byte]$xorkey[$i%$xorkey.count])
        }
        $UUID = [System.Convert]::ToBase64String($out)
        #Create new byte array
        [byte[]]$byteArray = [byte[]]::new($words)
        #Copy to ByteArray
        try{
            [System.Array]::Copy([System.Text.Encoding]::ASCII.GetBytes($UUID), $byteArray, [system.Math]::Min($words,$UUID.Length));
        }
        catch{
            Write-Verbose "Unable to copy to ByteArray"
            $byteArray = $null
        }
    }
    Process{
        if($null -ne $byteArray){
            foreach($elem in $byteArray){
                [void]$human_array.Add($default_wordlist.Item($elem))
            }
        }
        if($human_array.Count -gt 0){
            $output = [System.String]::Join($separator,$human_array.ToArray());
        }
        else{
            Write-Verbose "Unable to get human readable GUID. Generating a new GUID"
            $output = ([system.guid]::NewGuid()).ToString()
        }
    }
    End{
        $output
    }
}