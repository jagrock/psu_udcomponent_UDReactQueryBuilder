$devHash = Get-FileHash .\project\UDReactQueryBuilder.psm1
$outHash = Get-FileHash .\output\UDReactQueryBuilder.psm1

if ($devHash.Hash -ne $outHash.Hash) {
    Write-Host 'Update Output File'

    Copy-Item .\project\UDReactQueryBuilder.psm1 -Destination .\output -Force

    Write-Host "Updated:  $((Get-FileHash .\project\UDReactQueryBuilder.psm1).Hash -eq (Get-FileHash .\output\UDReactQueryBuilder.psm1).Hash)"
}

$psuModuleFolder = 'D:\Programs\psu\psu_Custom_Component_Testing\Repository\Modules\UDReactQueryBuilder\0.0.1'
Get-ChildItem -Path $psuModuleFolder -Filter 'index.*.bundle*' | Remove-Item -Force
Get-ChildItem .\output\ | Copy-Item -Destination $psuModuleFolder  -Force