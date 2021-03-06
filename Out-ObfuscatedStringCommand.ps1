#    This file is part of Invoke-Obfuscation.
#
#   Copyright 2016 Daniel Bohannon <@danielhbohannon>
#         while at Mandiant <http://www.mandiant.com>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.



Function Out-ObfuscatedStringCommand
{
<#
.SYNOPSIS

Master function that orchestrates the application of all string-based obfuscation functions to provided PowerShell script.

Invoke-Obfuscation Function: Out-ObfuscatedStringCommand
Author: Daniel Bohannon (@danielhbohannon)
License: Apache License, Version 2.0
Required Dependencies: Out-EncapsulatedInvokeExpression (located in Out-ObfuscatedStringCommand.ps1)
Optional Dependencies: None
 
.DESCRIPTION

Out-ObfuscatedStringCommand orchestrates the application of all string-based obfuscation functions (casting ENTIRE command to a string a performing string obfuscation functions) to provided PowerShell script to evade detection by simple IOCs and process execution monitoring relying solely on command-line arguments. If no $ObfuscationLevel is defined then Out-ObfuscatedStringCommand will automatically choose a random obfuscation level.
The available ObfuscationLevel/function mappings are:
1 --> Out-StringDelimitedAndConcatenated
2 --> Out-StringDelimitedConcatenatedAndReordered
3 --> Out-StringReversed

.PARAMETER ScriptBlock

Specifies a scriptblock containing your payload.

.PARAMETER Path

Specifies the path to your payload.

.PARAMETER ObfuscationLevel

(Optional) Specifies the obfuscation level for the given input PowerShell payload. If not defined then Out-ObfuscatedStringCommand will automatically choose a random obfuscation level. 
The available ObfuscationLevel/function mappings are:
1 --> Out-StringDelimitedAndConcatenated
2 --> Out-StringDelimitedConcatenatedAndReordered
3 --> Out-StringReversed

.EXAMPLE

C:\PS> Out-ObfuscatedStringCommand {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green} 1

IEX ((('Write-H'+'ost x'+'lcHello'+' Wor'+'ld!xlc -F'+'oregroundC'+'o'+'lor Gre'+'en'+'; Write-Host '+'xlcObf'+'u'+'sc'+'ation '+'Rocks!xl'+'c'+' '+'-'+'Foregrou'+'nd'+'C'+'olor Green')  -Replace 'xlc',[Char]39) )

C:\PS> Out-ObfuscatedStringCommand {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green} 2

IEX( (("{17}{1}{6}{19}{14}{3}{5}{13}{16}{11}{20}{15}{10}{12}{2}{4}{8}{18}{7}{9}{0}" -f ' Green','-H',' ',' ','R','-Foregr','ost qR9He','!qR9 -Foregr','o','oundColor','catio',' ','n','oundColor','qR9','bfus',' Green; Write-Host','Write','cks','llo World!','qR9O')).Replace('qR9',[String][Char]39))

C:\PS> Out-ObfuscatedStringCommand {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green} 3

$I4 ="noisserpxE-ekovnI|)93]rahC[]gnirtS[,'1Yp'(ecalpeR.)'ne'+'erG roloCd'+'nuo'+'rgero'+'F- 1'+'Y'+'p!s'+'kcoR'+' noit'+'a'+'cs'+'ufbO'+'1'+'Yp '+'tsoH'+'-etirW'+' ;'+'neer'+'G '+'rol'+'oCdnu'+'orger'+'o'+'F'+'-'+' 1'+'Yp'+'!dlroW '+'olleH1Yp '+'t'+'s'+'oH-et'+'irW'( " ;$I4[ -1 ..- ($I4.Length ) ] -Join '' | Invoke-Expression

.NOTES

Out-ObfuscatedStringCommand orchestrates the application of all string-based obfuscation functions (casting ENTIRE command to a string a performing string obfuscation functions) to provided PowerShell script to evade detection by simple IOCs and process execution monitoring relying solely on command-line arguments. If no $ObfuscationLevel is defined then Out-ObfuscatedStringCommand will automatically choose a random obfuscation level.
This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    [CmdletBinding( DefaultParameterSetName = 'FilePath')] Param (
        [Parameter(Position = 0, ValueFromPipeline = $True, ParameterSetName = 'ScriptBlock')]
        [ValidateNotNullOrEmpty()]
        [ScriptBlock]
        $ScriptBlock,

        [Parameter(Position = 0, ParameterSetName = 'FilePath')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,

        [ValidateSet('1', '2', '3')]
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $ObfuscationLevel = (Get-Random -Input @(1..3)) # Default to random obfuscation level if $ObfuscationLevel isn't defined
    )

    # Either convert ScriptBlock to a String or convert script at $Path to a String.
    If($PSBoundParameters['Path'])
    {
        Get-ChildItem $Path -ErrorAction Stop | Out-Null
        $ScriptString = [IO.File]::ReadAllText((Resolve-Path $Path))
    }
    Else
    {
        $ScriptString = [String]$ScriptBlock
    }

    # Set valid obfuscation levels for current token type.
    $ValidObfuscationLevels = @(0,1,2,3)
    
    # If invalid obfuscation level is passed to this function then default to highest obfuscation level available for current token type.
    If($ValidObfuscationLevels -NotContains $ObfuscationLevel) {$ObfuscationLevel = $ValidObfuscationLevels | Sort-Object -Descending | Select-Object -First 1}  
    
    Switch($ObfuscationLevel)
    {
        0 {Continue}
        1 {$ScriptString = Out-StringDelimitedAndConcatenated $ScriptString}
        2 {$ScriptString = Out-StringDelimitedConcatenatedAndReordered $ScriptString}
        3 {$ScriptString = Out-StringReversed $ScriptString}
        default {Write-Error "An invalid `$ObfuscationLevel value ($ObfuscationLevel) was passed to switch block for String Obfuscation."; Exit}
    }

    Return $ScriptString
}


Function Out-StringDelimitedAndConcatenated
{
<#
.SYNOPSIS

Generates delimited and concatenated version of input PowerShell command.

Invoke-Obfuscation Function: Out-StringDelimitedAndConcatenated
Author: Daniel Bohannon (@danielhbohannon)
License: Apache License, Version 2.0
Required Dependencies: Out-ConcatenatedString (located in Out-ObfuscatedTokenCommand.ps1), Out-EncapsulatedInvokeExpression (located in Out-ObfuscatedStringCommand.ps1)
Optional Dependencies: None
 
.DESCRIPTION

Out-StringDelimitedAndConcatenated delimits and concatenates an input PowerShell command. The purpose is to highlight to the Blue Team that there are more novel ways to encode a PowerShell command other than the most common Base64 approach.

.PARAMETER ScriptString

Specifies the string containing your payload.

.EXAMPLE

C:\PS> Out-StringDelimitedAndConcatenated "Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green"

(('Write-Ho'+'s'+'t'+' {'+'0'+'}'+'Hell'+'o Wor'+'l'+'d!'+'{'+'0'+'} -Foreground'+'Color G'+'ree'+'n; Writ'+'e-'+'H'+'ost {0}Obf'+'usc'+'a'+'tion R'+'o'+'ck'+'s!{'+'0} -Fo'+'reg'+'ro'+'undColor'+' '+'Gree'+'n')-F[Char]39) | Invoke-Expression

.NOTES

This cmdlet is most easily used by passing a script block or file path to a PowerShell script into the Out-ObfuscatedStringCommand function with the corresponding obfuscation level since Out-Out-ObfuscatedStringCommand will handle calling this current function where necessary.
C:\PS> Out-ObfuscatedStringCommand {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green} 1
This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    [CmdletBinding()] Param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ScriptString
    )
    
    # Characters we will substitute (in random order) with randomly generated delimiters.
    $CharsToReplace = @('$','|','`','\','"',"'")
    $CharsToReplace = (Get-Random -Input $CharsToReplace -Count $CharsToReplace.Count)

    # If $ScriptString does not contain any characters in $CharsToReplace then simply return as is.
    $ContainsCharsToReplace = $FALSE
    ForEach($CharToReplace in $CharsToReplace)
    {
        If($ScriptString.Contains($CharToReplace))
        {
            $ContainsCharsToReplace = $TRUE
            Break
        }
    }
    If(!$ContainsCharsToReplace)
    {
        # Concatenate $ScriptString as a string and then encapsulate with parentheses.
        $ScriptString = Out-ConcatenatedString $ScriptString "'"
        $ScriptString = '(' + $ScriptString + ')'

        # Encapsulate in necessary IEX/Invoke-Expression(s).
        $ScriptString = Out-EncapsulatedInvokeExpression $ScriptString

        Return $ScriptString
    }
    
    # Characters we will use to generate random delimiters to replace the above characters.
    # For simplicity do NOT include single- or double-quotes in this array.
    $CharsToReplaceWith  = @(0..9)
    $CharsToReplaceWith += @('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z')
    $CharsToReplaceWith += @('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z')
    $DelimiterLength = 3
    
    # Multi-dimensional table containing delimiter/replacement key pairs for building final command to reverse substitutions.
    $DelimiterTable = @()
    
    # Iterate through and replace each character in $CharsToReplace in $ScriptString with randomly generated delimiters.
    ForEach($CharToReplace in $CharsToReplace)
    {
        If($ScriptString.Contains($CharToReplace))
        {
            # Create random delimiter of length $DelimiterLength with characters from $CharsToReplaceWith.
            If($CharsToReplaceWith.Count -lt $DelimiterLength) {$DelimiterLength = $CharsToReplaceWith.Count}
            $Delim = (Get-Random -Input $CharsToReplaceWith -Count $DelimiterLength) -Join ''
            
            # Keep generating random delimiters until we find one that is not a substring of $ScriptString.
            While($ScriptString.ToLower().Contains($Delim.ToLower()))
            {
                $Delim = (Get-Random -Input $CharsToReplaceWith -Count $DelimiterLength) -Join ''
                If($DelimiterLength -lt $CharsToReplaceWith.Count)
                {
                    $DelimiterLength++
                }
            }
            
            # Add current delimiter/replacement key pair for building final command to reverse substitutions.
            $DelimiterTable += , @($Delim,$CharToReplace)

            # Replace current character to replace with the generated delimiter
            $ScriptString = $ScriptString.Replace($CharToReplace,$Delim)
        }
    }

    # Add random quotes to delimiters in $DelimiterTable.
    $DelimiterTableWithQuotes = @()
    ForEach($DelimiterArray in $DelimiterTable)
    {
        $Delimiter    = $DelimiterArray[0]
        $OriginalChar = $DelimiterArray[1]
        
        # Randomly choose between a single quote and double quote.
        $RandomQuote = Get-Random -InputObject @("'","`"")
        
        # Make sure $RandomQuote is opposite of $OriginalChar contents if it is a single- or double-quote.
        If($OriginalChar -eq "'") {$RandomQuote = '"'}
        Else {$RandomQuote = "'"}

        # Add quotes.
        $Delimiter = $RandomQuote + $Delimiter + $RandomQuote
        $OriginalChar = $RandomQuote + $OriginalChar + $RandomQuote
        
        # Add random quotes to delimiters in $DelimiterTable.
        $DelimiterTableWithQuotes += , @($Delimiter,$OriginalChar)
    }

    # Reverse the delimiters when building back out the reversing command.
    [Array]::Reverse($DelimiterTable)
    
    # Select random method for building command to reverse the above substitutions to execute the original command.
    # Avoid using the -f format operator (switch option 3) if curly braces are found in $ScriptString.
    If(($ScriptString.Contains('{')) -AND ($ScriptString.Contains('}')))
    {
        $RandomInput = Get-Random -Input (1..2)
    }
    Else
    {
        $RandomInput = Get-Random -Input (1..3)
    }
    
    Switch($RandomInput) {
        1 {
            # 1) .Replace

            $ScriptString = "'" + $ScriptString + "'"
            $ReversingCommand = ""

            ForEach($DelimiterArray in $DelimiterTableWithQuotes)
            {
                $Delimiter    = $DelimiterArray[0]
                $OriginalChar = $DelimiterArray[1]
                
                # Randomly decide if $OriginalChar will be displayed in ASCII representation or plaintext in $ReversingCommand.
                # This is to allow for simpler string manipulation on the command line.
                # Place priority on handling if $OriginalChar is a single- and double-quote.
                If($OriginalChar[1] -eq "'")
                {
                    $OriginalChar = "[String][Char]39"
                    $Delimiter = "'" + $Delimiter.SubString(1,$Delimiter.Length-2) + "'"
                }
                ElseIf($OriginalChar[1] -eq '"')
                {
                    $OriginalChar = "[String][Char]34"
                }
                Else
                {
                    If((Get-Random -Input (1..2)) % 2 -eq 0)
                    {
                        $OriginalChar = "[String][Char]" + [Int][Char]$OriginalChar[1]
                    }
                }
                
                # Randomly select if $Delimiter will be displayed in ASCII representation instead of plaintext in $ReversingCommand. 
                If((Get-Random -Input (1..2)) % 2 -eq 0)
                {
                    # Convert $Delimiter string into a concatenation of [Char] representations of each characters.
                    # This is to avoid redundant replacement of single quotes if this function is run numerous times back-to-back.
                    $DelimiterCharSyntax = ""
                    For($i=1; $i -lt $Delimiter.Length-1; $i++)
                    {
                        $DelimiterCharSyntax += '[Char]' + [Int][Char]$Delimiter[$i] + '+'
                    }
                    $Delimiter = '(' + $DelimiterCharSyntax.Trim('+') + ')'
                }
                
                # Add reversing commands to $ReversingCommand.
                $ReversingCommand = ".Replace($Delimiter,$OriginalChar)" + $ReversingCommand
            }

            # Concatenate $ScriptString as a string and then encapsulate with parentheses.
            $ScriptString = Out-ConcatenatedString $ScriptString "'"
            $ScriptString = '(' + $ScriptString + ')'

            # Add reversing commands to $ScriptString.
            $ScriptString = $ScriptString + $ReversingCommand
        }
        2 {
            # 2) -Replace/-CReplace

            $ScriptString = "'" + $ScriptString + "'"
            $ReversingCommand = ""

            ForEach($DelimiterArray in $DelimiterTableWithQuotes)
            {
                $Delimiter    = $DelimiterArray[0]
                $OriginalChar = $DelimiterArray[1]
                
                # Randomly decide if $OriginalChar will be displayed in ASCII representation or plaintext in $ReversingCommand.
                # This is to allow for simpler string manipulation on the command line.
                # Place priority on handling if $OriginalChar is a single- or double-quote.
                If($OriginalChar[1] -eq '"')
                {
                    $OriginalChar = "[Char]34"
                }
                ElseIf($OriginalChar[1] -eq "'")
                {
                    $OriginalChar = "[Char]39"; $Delimiter = "'" + $Delimiter.SubString(1,$Delimiter.Length-2) + "'"
                }
                Else
                {
                    $OriginalChar = "[Char]" + [Int][Char]$OriginalChar[1]
                }
                
                # Randomly select if $Delimiter will be displayed in ASCII representation instead of plaintext in $ReversingCommand. 
                If((Get-Random -Input (1..2)) % 2 -eq 0)
                {
                    # Convert $Delimiter string into a concatenation of [Char] representations of each characters.
                    # This is to avoid redundant replacement of single quotes if this function is run numerous times back-to-back.
                    $DelimiterCharSyntax = ""
                    For($i=1; $i -lt $Delimiter.Length-1; $i++)
                    {
                        $DelimiterCharSyntax += '[Char]' + [Int][Char]$Delimiter[$i] + '+'
                    }
                    $Delimiter = '(' + $DelimiterCharSyntax.Trim('+') + ')'
                }
                
                # Randomly choose between -Replace and the lesser-known case-sensitive -CReplace.
                $Replace = (Get-Random -Input @('-Replace','-CReplace'))
                
                # Add reversing commands to $ReversingCommand. Whitespace before and after $Replace is optional.
                $ReversingCommand = ' '*(Get-Random -Minimum 0 -Maximum 3) + $Replace + ' '*(Get-Random -Minimum 0 -Maximum 3) + "$Delimiter,$OriginalChar" + $ReversingCommand                
            }

            # Concatenate $ScriptString as a string and then encapsulate with parentheses.
            $ScriptString = Out-ConcatenatedString $ScriptString "'"
            $ScriptString = '(' + $ScriptString + ')'

            # Add reversing commands to $ScriptString.
            $ScriptString = '(' + $ScriptString + $ReversingCommand + ')'
        }
        3 {
            # 3) -f format operator

            $ScriptString = "'" + $ScriptString + "'"
            $ReversingCommand = ""
            $Counter = 0

            # Iterate delimiters in reverse for simpler creation of the proper order for $ReversingCommand.
            For($i=$DelimiterTableWithQuotes.Count-1; $i -ge 0; $i--)
            {
                $DelimiterArray = $DelimiterTableWithQuotes[$i]
                
                $Delimiter    = $DelimiterArray[0]
                $OriginalChar = $DelimiterArray[1]
                
                $DelimiterNoQuotes = $Delimiter.SubString(1,$Delimiter.Length-2)
                
                # Randomly decide if $OriginalChar will be displayed in ASCII representation or plaintext in $ReversingCommand.
                # This is to allow for simpler string manipulation on the command line.
                # Place priority on handling if $OriginalChar is a single- or double-quote.
                If($OriginalChar[1] -eq '"')
                {
                    $OriginalChar = "[Char]34"
                }
                ElseIf($OriginalChar[1] -eq "'")
                {
                    $OriginalChar = "[Char]39"; $Delimiter = "'" + $Delimiter.SubString(1,$Delimiter.Length-2) + "'"
                }
                Else
                {
                    $OriginalChar = "[Char]" + [Int][Char]$OriginalChar[1]
                }
                
                # Build out delimiter order to add as arguments to the final -f format operator.
                $ReversingCommand = $ReversingCommand + ",$OriginalChar"

                # Substitute each delimited character with placeholder for -f format operator.
                $ScriptString = $ScriptString.Replace($DelimiterNoQuotes,"{$Counter}")

                $Counter++
            }
            
            # Trim leading comma from $ReversingCommand.
            $ReversingCommand = $ReversingCommand.Trim(',')

            # Concatenate $ScriptString as a string and then encapsulate with parentheses.
            $ScriptString = Out-ConcatenatedString $ScriptString "'"
            $ScriptString = '(' + $ScriptString + ')'
            
            # Add reversing commands to $ScriptString. Whitespace before and after -f format operator is optional.
            $FormatOperator = (Get-Random -Input @('-f','-F'))

            $ScriptString = '(' + $ScriptString + ' '*(Get-Random -Minimum 0 -Maximum 3) + $FormatOperator + ' '*(Get-Random -Minimum 0 -Maximum 3) + $ReversingCommand + ')'
        }
        default {Write-Error "An invalid `$RandomInput value ($RandomInput) was passed to switch block."; Exit;}
    }

    # Encapsulate in necessary IEX/Invoke-Expression(s).
    $ScriptString = Out-EncapsulatedInvokeExpression $ScriptString
    
    Return $ScriptString
}


Function Out-StringDelimitedConcatenatedAndReordered
{
<#
.SYNOPSIS

Generates delimited, concatenated and reordered version of input PowerShell command.

Invoke-Obfuscation Function: Out-StringDelimitedConcatenatedAndReordered
Author: Daniel Bohannon (@danielhbohannon)
License: Apache License, Version 2.0
Required Dependencies: Out-StringDelimitedAndConcatenated (located in Out-ObfuscatedStringCommand.ps1)
Optional Dependencies: None
 
.DESCRIPTION

Out-StringDelimitedConcatenatedAndReordered delimits, concatenates and reorders the concatenated substrings of an input PowerShell command. The purpose is to highlight to the Blue Team that there are more novel ways to encode a PowerShell command other than the most common Base64 approach.

.PARAMETER ScriptString

Specifies the string containing your payload.

.EXAMPLE

C:\PS> Out-StringDelimitedConcatenatedAndReordered "Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green"

(("{16}{5}{6}{14}{3}{19}{15}{10}{18}{17}{0}{2}{7}{8}{12}{9}{11}{4}{13}{1}"-f't','en','ion R','9 -Fore','Gr','e-Host 0i9Hello W','or','ocks!0i9 -Fo','regroun','olo','ite-Hos','r ','dC','e','ld!0i','; Wr','Writ','sca','t 0i9Obfu','groundColor Green')).Replace('0i9',[String][Char]39) |IEX

.NOTES

This cmdlet is most easily used by passing a script block or file path to a PowerShell script into the Out-ObfuscatedStringCommand function with the corresponding obfuscation level since Out-Out-ObfuscatedStringCommand will handle calling this current function where necessary.
C:\PS> Out-ObfuscatedStringCommand {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green} 2
This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    [CmdletBinding()] Param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ScriptString
    )

    # Convert $ScriptString to delimited and concatenated string.
    $ScriptString = Out-StringDelimitedAndConcatenated $ScriptString
    
    # Parse out concatenated strings to re-order them.
    $Tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptString,[ref]$null)
    $GroupStartCount = 0
    $ConcatenatedStringsIndexStart = $NULL
    $ConcatenatedStringsIndexEnd   = $NULL
    $ConcatenatedStringsArray = @()
    For($i=0; $i -le $Tokens.Count-1; $i++) {
        $Token = $Tokens[$i]

        If(($Token.Type -eq 'GroupStart') -AND ($Token.Content -eq '('))
        {
            $GroupStartCount = 1
            $ConcatenatedStringsIndexStart = $Token.Start+1
        }
        ElseIf(($Token.Type -eq 'GroupEnd') -AND ($Token.Content -eq ')') -OR ($Token.Type -eq 'Operator') -AND ($Token.Content -ne '+'))
        {
            $GroupStartCount--
            $ConcatenatedStringsIndexEnd = $Token.Start
            # Stop parsing concatenated string.
            If($GroupStartCount -eq 0)
            {
                Break
            }
        }
        ElseIf($Token.Type -eq 'String')
        {
            $ConcatenatedStringsArray += $Token.Content
        }
    }

    $ConcatenatedStrings = $ScriptString.SubString($ConcatenatedStringsIndexStart,$ConcatenatedStringsIndexEnd-$ConcatenatedStringsIndexStart)
    
    # Randomize the order of the concatenated strings.
    $RandomIndexes = (Get-Random -Input (0..$($ConcatenatedStringsArray.Count-1)) -Count $ConcatenatedStringsArray.Count)
    
    $Arguments1 = ''
    $Arguments2 = @('')*$ConcatenatedStringsArray.Count
    For($i=0; $i -lt $ConcatenatedStringsArray.Count; $i++)
    {
        $RandomIndex = $RandomIndexes[$i]
        $Arguments1 += '{' + $RandomIndex + '}'
        $Arguments2[$RandomIndex] = "'" + $ConcatenatedStringsArray[$i] + "'"
    }
    
    # Whitespace is not required before or after the -f operator.
    $ScriptStringReordered = '(' + '"' + $Arguments1 + '"' + ' '*(Get-Random @(0..1)) + '-f' + ' '*(Get-Random @(0..1)) + ($Arguments2 -Join ',') + ')'
    
    # Add re-ordered $ScriptString back into the original $ScriptString context.
    $ScriptString = $ScriptString.SubString(0,$ConcatenatedStringsIndexStart) + $ScriptStringReordered + $ScriptString.SubString($ConcatenatedStringsIndexEnd)
    
    Return $ScriptString
}


Function Out-StringReversed
{
<#
.SYNOPSIS

Generates concatenated and reversed version of input PowerShell command.

Invoke-Obfuscation Function: Out-StringReversed
Author: Daniel Bohannon (@danielhbohannon)
License: Apache License, Version 2.0
Required Dependencies: Out-ConcatenatedString (located in Out-ObfuscatedToken.ps1)
Optional Dependencies: None
 
.DESCRIPTION

Out-StringReversed concatenates and reverses an input PowerShell command. The purpose is to highlight to the Blue Team that there are more novel ways to encode a PowerShell command other than the most common Base64 approach.

.PARAMETER ScriptString

Specifies the string containing your payload.

.EXAMPLE

C:\PS> Out-StringReversed "Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green"

$IU = [char[ ]]" ) )93]rahC[,)15]rahC[+45]rahC[+88]rahC[(  ecalpeR- )'nee'+'rG roloCdnuorgeroF-'+' 36X'+'!skcoR '+'noit'+'a'+'csu'+'fbO3'+'6X '+'tso'+'H-e'+'ti'+'rW ;neerG roloCdn'+'u'+'o'+'rg'+'ero'+'F- 36X!dlroW olleH36X '+'ts'+'oH-etirW'(( (noisserpxE-ekovnI "; [Array]::Reverse($IU ); $IU-Join ''|IEX

.NOTES

This cmdlet is most easily used by passing a script block or file path to a PowerShell script into the Out-ObfuscatedStringCommand function with the corresponding obfuscation level since Out-Out-ObfuscatedStringCommand will handle calling this current function where necessary.
C:\PS> Out-ObfuscatedStringCommand {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green} 3
This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    [CmdletBinding()] Param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ScriptString
    )

    # Remove any special characters to simplify dealing with the reversed $ScriptString on the command line.
    $ScriptString = Out-ObfuscatedStringCommand ([ScriptBlock]::Create($ScriptString)) 1

    # Reverse $ScriptString.
    $ScriptStringReversed = $ScriptString[-1..-($ScriptString.Length)] -Join ''
    
    # Add random invoke operation.
    $InvokeExpression = @('IEX','Invoke-Expression')
    
    # Characters we will use to generate random variable names.
    # For simplicity do NOT include single- or double-quotes in this array.
    $CharsToRandomVarName  = @(0..9)
    $CharsToRandomVarName += @('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z')

    $RandomVarLength = 2
   
    # Create random variable with characters from $CharsToReplaceWith.
    If($CharsToRandomVarName.Count -lt $RandomVarLength) {$RandomVarLength = $CharsToRandomVarName.Count}
    $RandomVar = '$' + ((Get-Random -Input $CharsToRandomVarName -Count $RandomVarLength) -Join '').Replace(' ','')
    
    # Keep generating random variables until we find one that is not a substring of $ScriptString.
    While($ScriptString.Contains($RandomVar))
    {
        $RandomVar = '$' + ((Get-Random -Input $CharsToRandomVarName -Count $RandomVarLength) -Join '').Replace(' ','')
        $RandomVarLength++
    }
    
    # Select random method for building command to reverse the now-reversed $ScriptString to execute the original command.
    Switch(Get-Random -Input (1..3)) {
        1 {
            # 1) $String[-1..-($String.Length)] -Join ''
            
            # Set $ScriptStringReversed as environment variable $Random.
            $ScriptString = $RandomVar + ' '*(Get-Random -Input @(0,1)) + '=' + ' '*(Get-Random -Input @(0,1)) + '"' + $ScriptStringReversed + '"' + ' '*(Get-Random -Input @(0,1)) + ';'
            
            $RandomVar = $RandomVar + '[' + ' '*(Get-Random -Input @(0,1)) + '-' + ' '*(Get-Random -Input @(0,1)) + '1' + ' '*(Get-Random -Input @(0,1)) + '..' + ' '*(Get-Random -Input @(0,1)) + '-' + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + $RandomVar + '.Length' + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + ']'
            
            # Build out random syntax depending on whether -Join is prepended or -Join '' is appended.
            $JoinOptions  = @()
            $JoinOptions += '-Join' + ' '*(Get-Random -Input @(0,1)) + $RandomVar
            $JoinOptions += $RandomVar + ' '*(Get-Random -Input @(0,1)) + '-Join' + ' '*(Get-Random -Input @(0,1)) + "''"
            $JoinOption = (Get-Random -Input $JoinOptions)
            
            # Encapsulate in necessary IEX/Invoke-Expression(s).
            $JoinOption = Out-EncapsulatedInvokeExpression $JoinOption
            
            $ScriptString = $ScriptString + $JoinOption
        }
        2 {
            # 2) StringArray = [Char[]]$String; [Array]::Reverse($StringArray); $StringArray -Join ''
            
            # Build out random syntax depending on whether -Join is prepended or -Join '' is appended.
            $ScriptString = $RandomVar + ' '*(Get-Random -Input @(0,1)) + '=' + ' '*(Get-Random -Input @(0,1)) + '[char[' + ' '*(Get-Random -Input @(0,1)) + ']' + ' '*(Get-Random -Input @(0,1)) + ']' + ' '*(Get-Random -Input @(0,1)) + '"' + $ScriptStringReversed + '"' + ' '*(Get-Random -Input @(0,1)) + ';'
            $ScriptString = $ScriptString + ' '*(Get-Random -Input @(0,1)) + '[Array]::Reverse(' + ' '*(Get-Random -Input @(0,1)) + $RandomVar + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + ';'

            $JoinOptions  = @()
            $JoinOptions += '-Join' + ' '*(Get-Random -Input @(0,1)) + $RandomVar
            $JoinOptions += $RandomVar + ' '*(Get-Random -Input @(0,1)) + '-Join' + ' '*(Get-Random -Input @(0,1)) + "''"
            $JoinOption = (Get-Random -Input $JoinOptions)
            
            # Encapsulate in necessary IEX/Invoke-Expression(s).
            $JoinOption = Out-EncapsulatedInvokeExpression $JoinOption
            
            $ScriptString = $ScriptString + $JoinOption
        }
        3 {
            # 3) -Join[Regex]::Matches($StringArray,'.','RightToLeft')            
            
            # Randomly choose to use 'RightToLeft' or concatenated version of this string in $JoinOptions below.
            If((Get-Random -Input (1..2)) % 2 -eq 0)
            {
                $RightToLeft = Out-ConcatenatedString 'RightToLeft' "'"
            }
            Else
            {
                $RightToLeft = "'RightToLeft'"
            }
            
            # Build out random syntax depending on whether -Join is prepended or -Join '' is appended.
            $JoinOptions  = @()
            $JoinOptions += ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + '-Join' + ' '*(Get-Random -Input @(0,1)) + '[Regex]::Matches(' + ' '*(Get-Random -Input @(0,1)) + '"' + $ScriptStringReversed + ' '*(Get-Random -Input @(0,1)) + '"' + ' '*(Get-Random -Input @(0,1)) + ',' + ' '*(Get-Random -Input @(0,1)) + "'.'" + ' '*(Get-Random -Input @(0,1)) + ',' + ' '*(Get-Random -Input @(0,1)) + $RightToLeft + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1))
            $JoinOptions += ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + '[Regex]::Matches(' + ' '*(Get-Random -Input @(0,1)) + '"' + $ScriptStringReversed + ' '*(Get-Random -Input @(0,1)) + '"' + ' '*(Get-Random -Input @(0,1)) + ',' + ' '*(Get-Random -Input @(0,1)) + "'.'" + ' '*(Get-Random -Input @(0,1)) + ',' +  ' '*(Get-Random -Input @(0,1)) + $RightToLeft + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + '-Join' + ' '*(Get-Random -Input @(0,1)) + "''" + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1))
            $ScriptString = (Get-Random -Input $JoinOptions)
            
            # Encapsulate in necessary IEX/Invoke-Expression(s).
            $ScriptString = Out-EncapsulatedInvokeExpression $ScriptString
        }
        default {Write-Error "An invalid value was passed to switch block."; Exit;}
    }
    
    # Perform final check to remove ticks if they now precede lowercase special characters after the string is reversed.
    # E.g. "testin`G" in reverse would be "G`nitset" where `n would be interpreted as a newline character.
    $SpecialCharacters = @('a','b','f','n','r','t','v','0')
    ForEach($SpecialChar in $SpecialCharacters)
    {
        If($ScriptString.Contains("``"+$SpecialChar))
        {
            $ScriptString = $ScriptString.Replace("``"+$SpecialChar,$SpecialChar)
        }
    }
    
    Return $ScriptString
}


Function Out-EncapsulatedInvokeExpression
{
<#
.SYNOPSIS

HELPER FUNCTION :: Generates random syntax for invoking input PowerShell command.

Invoke-Obfuscation Function: Out-EncapsulatedInvokeExpression
Author: Daniel Bohannon (@danielhbohannon)
License: Apache License, Version 2.0
Required Dependencies: None
Optional Dependencies: None
 
.DESCRIPTION

Out-EncapsulatedInvokeExpression generates random syntax for invoking input PowerShell command. It uses a combination of IEX and Invoke-Expression as well as ordering (IEX $Command , $Command | IEX).

.PARAMETER ScriptString

Specifies the string containing your payload.

.EXAMPLE

C:\PS> Out-EncapsulatedInvokeExpression {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green}

Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green|Invoke-Expression

.NOTES

This cmdlet is most easily used by passing a script block or file path to a PowerShell script into the Out-ObfuscatedStringCommand function with the corresponding obfuscation level since Out-Out-ObfuscatedStringCommand will handle calling this current function where necessary.
C:\PS> Out-ObfuscatedStringCommand {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green} 1
C:\PS> Out-ObfuscatedStringCommand {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green} 2
C:\PS> Out-ObfuscatedStringCommand {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green} 3
This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    [CmdletBinding()] Param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ScriptString
    )

    # Add random invoke operation.
    $InvokeExpression = @('IEX','Invoke-Expression')
    
    # Choose random Invoke-Expression/IEX syntax and ordering: IEX ($ScriptString) or ($ScriptString | IEX)
    $InvokeOptions  = @()
    $InvokeOptions += ' '*(Get-Random -Input @(0,1)) + (Get-Random -Input $InvokeExpression) + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + $ScriptString + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1))
    $InvokeOptions += ' '*(Get-Random -Input @(0,1)) + $ScriptString + ' '*(Get-Random -Input @(0,1)) + '|' + ' '*(Get-Random -Input @(0,1)) + (Get-Random -Input $InvokeExpression)

    $ScriptString = (Get-Random -Input $InvokeOptions)

    Return $ScriptString
}