$OutputPath = ".\output\"
#$OutputPath = "$PSScriptRoot\output"

#region clean up folders
Remove-Item -Path $OutputPath -Force -ErrorAction SilentlyContinue -Recurse
Remove-Item -Path ".\project\public" -Force -ErrorAction SilentlyContinue -Recurse

#endregion

#region build component
Push-Location -Path .\project
npm install
npm run build
#npm run buildNoMini
Pop-Location
#endregion

#region Build Output
New-Item -Path $OutputPath -ItemType Directory
Get-ChildItem .\project\public\ | Unblock-File
Copy-Item .\project\public\*.* -Destination .\Output
Copy-Item .\project\\UDReactQueryBuilder.psd1 -Destination $OutputPath
Copy-Item .\project\UDReactQueryBuilder.psm1 -Destination $OutputPath
Get-ChildItem .\output | Unblock-File
#endregion


#region Copy to PSU
$psuModuleFolder = 'D:\Programs\psu\psu_Custom_Component_Testing\Repository\Modules\UDReactQueryBuilder\0.0.1'
Get-ChildItem -Path $psuModuleFolder -Filter 'index.*.bundle*' | Remove-Item -Force
Get-ChildItem .\output\ | Copy-Item -Destination $psuModuleFolder  -Force

#endregion

