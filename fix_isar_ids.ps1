$files = Get-ChildItem -Path "lib\data\local\collections" -Filter "*.g.dart"
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $newContent = [regex]::Replace($content, 'id:\s*(-?\d{16,}),', {
        param($match)
        $numStr = $match.Groups[1].Value
        $sign = ""
        if ($numStr.StartsWith("-")) {
            $sign = "-"
            $numStr = $numStr.Substring(1)
        }
        $truncated = $numStr.Substring(0, 15)
        return "id: " + $sign + $truncated + ","
    })
    if ($content -ne $newContent) {
        Set-Content -Path $file.FullName -Value $newContent
        Write-Host "Patched $($file.Name)"
    }
}
