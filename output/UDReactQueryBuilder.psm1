
$IndexJs = Get-ChildItem "$PSScriptRoot\index.*.bundle.js"
$AssetId = [UniversalDashboard.Services.AssetService]::Instance.RegisterAsset($IndexJs.FullName)

<#
https://react-querybuilder.js.org/

To-Do:
Initial Query
Option to convert dates to timestamp/filetime
Better ParseNumbers Support
*-UDElement Support
Custom Operator support ?New-UDRQBOperator?
Include more RQB customization options (e.g. combinators between nodes, dateTimePackage, validation, suppress standard classes, antD, etc.. ).
Example with on page config
Update to latest RQB - locked to 7.7.1 - when React Mini Error 31 issue resolved
More FieldBuilder options (e.g. value source)
#>

function New-UDReactQueryBuilder {
    [CmdletBinding()]

    param(
        [Parameter()]
        [string]$Id = (New-Guid).ToString(),

        # Initial Query
        [Parameter()]
        [hashtable] $InitialQuery = $null,

        # Default Formats
        [Parameter()]
        [AllowEmptyString()]
        [ValidateSet('ldap', 'ldap_escaped', 'sql', 'json', 'json_without_ids', 'parameterized', 'parameterized_named', 'mongodb', 'mongodb_query', 'cel', 'jsonlogic', 'jsonata', 'elasticsearch', 'spel', 'natural_language')]
        [string[]] $Formats,
        
        # Custom Formats
        <# To Add Later - RQB 8.6 added this feature
        and ldap is now an included format - meeds tweaking
        #
        [Parameter()]
        [ValidateSet('ldap', 'ldap_escaped')]
        [string[]] $CustomFormats,
        #>

        # Fields
        [Parameter()]
        [scriptblock] $Fields,
        
        # Option - parseNumbers in Query
        [Parameter()]
        [AllowEmptyString()]
        [ValidateSet('true', 'default', "enhanced", "enhanced-limited", "native", "native-limited", "strict", "strict-limited")]
        [string] $ParseNumbers,
        
        # Option - parseNumbers on Format
        [Parameter()]
        [ValidateSet('default', "enhanced", "enhanced-limited", "native", "native-limited", "strict", "strict-limited")]
        [string[]] $FormatParseNumberOptions,

        # Set Options
        [Parameter()]
        [AllowEmptyString()]
        [ValidateSet('addRuleToNewGroups', 'showCloneButtons', 'showCombinatorsBetweenRules', 'showLockButtons', 'showNotToggle', 'showShiftActions')]
        [string[]] $Options,

        # Set control class names
        [Parameter()]
        [AllowEmptyString()]
        [ValidateSet('queryBuilder-branches', 'justifiedLayout')]
        [string[]] $ControlClassnames,

        # Show formatQuery options - use Event data for now
        [Parameter(DontShow=$true)]
        [switch] $ShowQueryFormatOption,

        # Show parseNumber options - use Event data for now
        [Parameter(DontShow=$true)]
        [switch] $ShowParseNumberOption,

        # Handle Changes
        [Parameter()]
        [Endpoint] $OnChange
    )
    begin {}
    process {

        if ($OnChange) {
            $OnChange.Register($Id, $PSCmdlet)
        }

        $hashProps = @{
            #PSU Required Props
            assetId               = $AssetId
            isPlugin              = $true
            type                  = "ud-reactquerybuilder"
            id                    = $Id
            onChange              = $OnChange
            
            #Component Props
            # The Props required by the component:  <QueryBuilder>
            # query, fields, options, controlClassnames
            query                 = @{ 
                combinator = 'and'
                rules = @()
            }
            queryBuilder          = @{}
            #showQueryFormatOption = $ShowQueryFormatOption
            #showParseNumberOption = $ShowParseNumberOption
        }

        #region Component Props        
        if ($PSBoundParameters.ContainsKey('Fields')) {
            $hashProps.queryBuilder.fields = [array]$Fields.Invoke()
            #$hashProps.fields = [array]$Fields.Invoke()
        }
        if ($PSBoundParameters.ContainsKey('Options') -and $null -ne $Options) {
            foreach ($opt in $Options) {
                $hashProps.queryBuilder.$opt = $true
                #$hashProps.$opt = $true
            }
        }
        if ($ParseNumbers) {
            #need to add support to return formatQuery with and without parsed numbers
            $hashProps.queryBuilder.parseNumbers = $ParseNumbers
            #$hashProps.parseNumbers = $parseNumbers
        }
        if ($PSBoundParameters.ContainsKey('controlClassnames') -and $null -ne $controlClassnames) {
            $hashProps.queryBuilder.controlClassnames = @{queryBuilder = $controlClassnames -join ' ' }
            #$hashProps.controlClassnames = @{queryBuilder = $controlClassnames -join ' ' }
        }
        #endregion
        
        #region Custom Props to Pass to Component
        if ($PSBoundParameters.ContainsKey('Formats')) {
            $hashProps.formats = [array]$Formats
        }
        
        #endregion
        
        return $hashProps
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
            'Contains',
            'BeginsWith',
            'EndsWith',
            'NotContains',
            'NotBeginsWith',
            'NotEndsWith',
            'isNull',
            'isNotNull',
            'in',
            'notIn',
            'Between',
            'notBetween'
        )]
        [string[]] $DefaultOperators,

        # LDAP/Custom Operators
        [Parameter()]
        [ValidateSet(
            'Like',
            'NotLike',
            'MemberOf',
            'NotMemberOf',
            'MemberOfRecursive',
            'NotMemberOfRecursive',
            'ExtensibleMatch',
            'NotExtensibleMatch',
            'MatchingRuleInChain',
            'NotMatchingRuleInChain',
            'BitWiseAnd',
            'NotBitWiseAnd',
            'BitWiseOr',
            'NotBitWiseOr'
        )]
        [string[]] $CustomOperators
    )
    Begin {
        
        $rqbOperators = @{
            #Default
            Equal                  = @{Value = '='; Label = '=' }
            NotEqual               = @{Value = '!='; Label = '!=' }
            
            GreaterThan            = @{Value = '>'; Label = '>' }
            GreaterThanOrEqual     = @{Value = '>='; Label = '>=' }
            
            LessThan               = @{Value = '<'; Label = '<' }
            LessThanOrEqual        = @{Value = '<='; Label = '<=' }
            
            Contains               = @{Value = 'contains'; Label = 'contains' }
            NotContains            = @{Value = 'doesNotContain'; Label = 'does not contain' }
            
            BeginsWith             = @{Value = 'beginsWith'; Label = 'begins with' }
            NotBeginsWith          = @{Value = 'doesNotBeginWith'; Label = 'does not begin with' }
            
            EndsWith               = @{Value = 'endsWith'; Label = 'ends with' }
            NotEndsWith            = @{Value = 'doesNotEndWith'; Label = 'does not end with' }
            
            isNull                 = @{Value = 'null'; Label = 'isNull' }
            isNotNull              = @{Value = 'notNull'; Label = 'is not null' }
            
            in                     = @{Value = 'in'; Label = 'in' }
            notIn                  = @{Value = 'notIn'; Label = 'not in' }
            
            Between                = @{Value = 'between'; Label = 'between' }
            notBetween             = @{Value = 'notBetween'; Label = ' not between' }
            
            #Custom
            Like                   = @{Value = 'like'; Label = 'like' }
            NotLike                = @{Value = 'notLike'; Label = 'not like' }
            
            MemberOf               = @{Value = 'memberOf'; Label = 'direct member of' }
            notMemberOf            = @{Value = 'notMemberOf'; Label = 'not direct member of' }

            MemberOfRecursive      = @{Value = 'memberOfRecursive'; Label = 'nested member of' }
            notMemberOfRecursive   = @{Value = 'notMemberOfRecursive'; Label = 'not nested member of' }
            
            MatchingRuleInChain    = @{Value = 'matchingRuleInChain'; Label = 'Matching Rule in Chain' }
            notMatchingRuleInChain = @{Value = 'notMatchingRuleInChain'; Label = 'not Matching Rule in Chain' }

            ExtensibleMatch        = @{Value = 'extensibleMatch'; Label = 'extensible match' }
            notExtensibleMatch     = @{Value = 'notExtensibleMatch'; Label = 'not extensible match' }

            BitWiseAnd             = @{Value = 'bitWiseAnd'; Label = 'Bitwise And' }
            notBitWiseAnd          = @{Value = 'notBitWiseAnd'; Label = 'not Bitwise And' }

            BitWiseOr              = @{Value = 'bitWiseOr'; Label = 'Bitwise Or' }
            notBitWiseOr           = @{Value = 'notBitWiseOr'; Label = 'not Bitwise Or' }
        
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
        if ($PSBoundParameters.ContainsKey('DefaultOperators') -or $PSBoundParameters.ContainsKey('CustomOperators')) {
            if ($field.ContainsKey('operators') -ne $true) {
                $field.operators = [System.Collections.Generic.List[object]]::new()
            }
        }

        switch ($PSBoundParameters.Keys) {
            'ValueEditorType' {
                $field.ValueEditorType = $ValueEditorType
            }

            'InputType' {
                $field.InputType = $InputType
            }

            'DefaultOperators' {
                foreach ($oper in $DefaultOperators) {
                    $field.operators.add([pscustomobject]$rqbOperators.$oper)
                }
            }

            'CustomOperators' {
                foreach ($oper in $CustomOperators) {
                    $field.operators.add([pscustomobject]$rqbOperators.$oper)                    
                }

                #$field.className = 'CustomOperator'
            }

        }

        return $field
    }

    End {
    }
}

    
