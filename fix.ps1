$content = Get-Content -Path 'lib\core\services\web_mock_isar.dart' -Raw
$newContent = [regex]::Replace($content, '\.\.(\w+)\s*=\s*map\[''([^'']+)''\] as double\?', '..$1 = (map[''$2''] as num?)?.toDouble()')
Set-Content -Path 'lib\core\services\web_mock_isar.dart' -Value $newContent
