Using Module .\ConvertFrom-GitDiff.psm1

Clear-Host

$example1 = (Get-Content -Path ".\Example1.txt" -Raw)

$diff = ConvertFrom-GitDiff -diffText $example1

($diff | ConvertTo-JSON -Depth 100) > ".\temp.json"