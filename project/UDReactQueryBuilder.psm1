
$IndexJs = Get-ChildItem "$PSScriptRoot\index.*.bundle.js"
#$IndexJs = Get-ChildItem "$PSScriptRoot\*.bundle.js"
$AssetId = [UniversalDashboard.Services.AssetService]::Instance.RegisterAsset($IndexJs.FullName)

function New-UDReactQueryBuilder {
    [CmdletBinding()]

    param(
        [Parameter()]
        [string]$Id = (New-Guid).ToString(),

        # Formats
        [Parameter()]
        [ValidateSet('ldap', 'sql', 'json', 'json_without_ids', 'parameterized', 'parameterized_named', 'mongodb', 'mongodb_query', 'cel', 'jsonlogic', 'jsonata', 'elasticsearch', 'spel', 'natural_language')]
        [string[]] $Formats,

        # Fields
        [Parameter()]
        [scriptblock] $Fields,

        # Option - Show Branches
        [Parameter()]
        [Obsolete("The -ShowBranches parameter is deprecated. Please use -controlClassnames instead.")]
        [switch] $ShowBranches,
        
        # Option - parseNumbers
        [Parameter()]
        [switch] $parseNumbers,

        # Set Options
        [Parameter()]
        [ValidateSet('addRuleToNewGroups', 'showCloneButtons', 'showCombinatorsBetweenRules', 'showLockButtons', 'showNotToggle', 'showShiftActions')]
        [string[]] $Options,

        # Set control class names
        [Parameter()]
        [ValidateSet('queryBuilder-branches', 'justifiedLayout')]
        [string[]] $controlClassnames
    )
    begin {}
    process {
        $hashRQB = @{
            assetId  = $AssetId
            isPlugin = $true
            type     = "ud-reactquerybuilder"
            id       = $Id
        }

        if ($PSBoundParameters.ContainsKey('Fields')) {
            $hashRQB.fields = [array]$Fields.Invoke()
        }
        if ($PSBoundParameters.ContainsKey('Formats')) {
            $hashRQB.formats = [array]$Formats
        }

        if ($parseNumbers) {
            $hashRQB.$parseNumbers = "strict-limited"
        }

        if ($PSBoundParameters.ContainsKey('Options')) {
            foreach ($opt in $Options) {
                $hashRQB.$opt = $true
            }
        }

        if ($PSBoundParameters.ContainsKey('controlClassnames')) {
            #$controls = "queryBuilder: '{0}" -f ($controlClassnames -join ' ')
            $hashRQB.controlClassnames = @{queryBuilder = $controlClassnames -join ' ' }
        }

        if ($ShowBranches) {
            if ($PSBoundParameters.ContainsKey('controlClassnames') -ne $true) {
                $hashRQB.controlClassnames = "queryBuilder: 'queryBuilder-branches'"
            }
            else {
                Write-Warning "The -ShowBranches parameter is deprecated. Please use -controlClassnames instead."
            }
        }
        

        if ($PSBoundParameters.ContainsKey('Verbose')) {
            $jsonParams = $PSBoundParameters | ConvertTo-Json
            Set-UDElement -Id 'qbParams' -Content {
                $jsonParams
                $PSScriptRoot
                New-UDTable -data $hashRQB
                New-UDTable -data ($PSBoundParameters)
            }
        }
        
        return $hashRQB
    }
    end {
    
    }
}

function New-UDReactQueryBuilderField {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter()]
        [string]$Label,
        
        [Parameter()]
        [string]$Placeholder,

        # Value Editor Type
        [Parameter()]
        [ValidateSet('text', 'select', 'checkbox', 'radio', 'textarea', 'multiselect', 'date', 'datetime-local', 'time')]
        [string] $ValueEditiorType,

        # Input Type
        [Parameter()]
        [ValidateSet('text', 'select', 'checkbox', 'radio', 'textarea', 'multiselect', 'date', 'datetime-local', 'time')]
        [string] $InputType,

        # Operators
        [Parameter()]
        [ValidateSet(
            'Equal',
            'NotEqual',
            'GreaterThan',
            'GreaterThanOrEqual',
            'LessThan',
            'LessThanOrEqual',
            'Contains', #Ldap like
            'BeginsWith',
            'EndsWith',
            'NotContains', #ldap NotLike
            'NotBeginsWith',
            'NotEndsWith',
            'isNull',
            'isNotNull',
            'in',
            'notIn',
            'Between',
            'notBetween'
        )]
        [string[]] $Operators,

        # LDAP Operators
        [Parameter()]
        [ValidateSet(
            'Like',
            'MemberOf',
            'MemberOfRecursive',
            'ExtensibleMatch'
        )]
        [string[]] $LdapOperators
    )
    Begin {
        
        $rqbOperators = @{
            Equal              = @{Value = '='; Label = '=' }
            NotEqual           = @{Value = '!='; Label = '!=' }
            GreaterThan        = @{Value = '>'; Label = '>' }
            GreaterThanOrEqual = @{Value = '>='; Label = '>=' }
            LessThan           = @{Value = '<'; Label = '<' }
            LessThanOrEqual    = @{Value = '<='; Label = '<=' }
            Contains           = @{Value = 'contains'; Label = 'contains' }
            BeginsWith         = @{Value = 'beginsWith'; Label = 'begins with' }
            EndsWith           = @{Value = 'endsWith'; Label = 'ends with' }
            NotContains        = @{Value = 'doesNotContains'; Label = 'does not contain' }
            NotBeginsWith      = @{Value = 'doesNotBeginWith'; Label = 'does not begin with' }
            NotEndsWith        = @{Value = 'doesNotEndWith'; Label = 'does not end with' }
            isNull             = @{Value = 'null'; Label = 'isNull' }
            isNotNull          = @{Value = 'notNull'; Label = 'is not null' }
            in                 = @{Value = 'in'; Label = 'in' }
            notIn              = @{Value = 'notIn'; Label = 'not in' }
            Between            = @{Value = 'between'; Label = 'between' }
            notBetween         = @{Value = 'notBetween'; Label = ' not between' }
            Like               = @{Value = 'like'; Label = 'like' }
            MemberOf           = @{Value = 'memberOf'; Label = 'direct member of' }
            MemberOfRecursive  = @{Value = 'memberOfRecursive'; Label = 'nested member of' }
            ExtensibleMatch    = @{Value = 'extensibleMatch'; Label = 'extensible match' }
        }        
        
        $field = @{}
    }

    Process {

        if ($null -eq $Label -or $label.length -eq 0) {
            $Label = $Name
        }

        $field.name = $Name
        $field.label = $Label

        if ($null -eq $Placeholder -or $Placeholder.length -eq 0) {
            $field.placeholder = $Placeholder
        }

        switch ($PSBoundParameters.Keys) {
            'ValueEditorType' {
                $field.ValueEditorType = $ValueEditorType
            }

            'InputType' {
                $field.InputType = $InputType
            }

            'Operators' {
                if ($field.ContainsKey('operators') -ne $true) {
                    $field.operators = [System.Collections.Generic.List[hashtable]]::new()
                }
                foreach ($oper in $operators) {
                    $field.operators.add($rqbOperators.$oper.clone())
                }
            }

            'LdapOperators' {
                if ($field.ContainsKey('operators') -ne $true) {
                    $field.operators = [System.Collections.Generic.List[hashtable]]::new()
                }
                foreach ($oper in $LdapOperators) {
                    $field.operators.add($rqbOperators.$oper.clone())
                }

                $field.className = 'ldapField'
            }

        }

        return $field
    }

    End {
    }
}

function Convert-JsonToLdapFilter {
    param (
        [string]$Json
    )

    function Convert-Rules($rulesObject) {
        $combinator = $rulesObject.combinator
        $rules = $rulesObject.rules
        $not = $rulesObject.not

        $ldapParts = @()

        foreach ($rule in $rules) {
            if ($rule.rules) {
                # Nested group
                $nested = Convert-Rules $rule
                $ldapParts += $nested
            }
            else {
                $field = $rule.field
                $operator = $rule.operator
                $value = $rule.value

                switch ($operator) {
                    '=' { $ldapParts += "($field=$value)" }
                    '!=' { $ldapParts += "(!($field=$value))" }
                    'beginsWith' { $ldapParts += "($field=$value*)" }
                    'contains' { $ldapParts += "($field=*$value*)" }
                    default { throw "Unsupported operator: $operator" }
                }
            }
        }

        # Combine rules based on combinator
        if ($combinator -eq 'and') {
            $filter = "(&" + ($ldapParts -join '') + ")"
        }
        elseif ($combinator -eq 'or') {
            $filter = "(|" + ($ldapParts -join '') + ")"
        }
        else {
            throw "Unsupported combinator: $combinator"
        }

        if ($not -eq $true) {
            $filter = "(!${filter})"
        }

        return $filter
    }

    $parsedJson = $Json | ConvertFrom-Json
    return Convert-Rules $parsedJson
}
    
