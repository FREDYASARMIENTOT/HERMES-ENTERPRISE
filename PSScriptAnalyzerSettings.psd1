@{
    # Exclude rules that are coding conventions, not bugs
    ExcludeRules = @(
        'PSUseBOMForUnicodeEncodedFile'
        'PSAvoidUsingWriteHost'
        'PSUseShouldProcessForStateChangingFunctions'
        'PSUseSingularNouns'
        'PSAvoidUsingCmdletAliases'
        'PSPossibleIncorrectComparisonWithNull'
        'PSUseDeclaredVarsMoreThanAssignments'
        'PSReviewUnusedParameter'
        'PSUseApprovedVerbs'
        'PSAvoidGlobalVars'
        'PSAvoidAssignmentToAutomaticVariable'
    )

    # Rules we still enforce
    Rules = @{
        PSAvoidUsingInvokeExpression = @{
            Enable = $true
            Severity = 'Error'
        }
    }
}