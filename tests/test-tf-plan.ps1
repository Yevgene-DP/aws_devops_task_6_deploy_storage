$tfPlanPath = "tfplan.json"

if (Test-Path $tfPlanPath) { 
    Write-Output "`u{2705} Checking if terrafom plan exists - OK. "
} else { 
    throw "`u{1F635} Unable to find terraform plan file. Please make sure that you saved terraform execution plan to the file and try again. "
}

$plan = (Get-Content -Path $tfPlanPath | ConvertFrom-Json) 

$s3 = $plan.configuration.root_module.resources | Where-Object {$_.type -eq "aws_s3_bucket"} 
if ($s3 -and ($s3.Count -eq 1 )) {
    Write-Output "`u{2705} Checking if S3 resource is present - OK. "
} else { 
    throw "`u{1F635} Unable to find S3 resource. Please make sure that you added it and try again. "
}

$policyDocument = $plan.configuration.root_module.resources | Where-Object {$_.type -eq "aws_iam_policy_document"}
if ($policyDocument  -and ($policyDocument.Count -eq 1 )) {
    Write-Output "`u{2705} Checking if policy document data source is present - OK. "
} else { 
    throw "`u{1F635} Unable to find policy document data source. Please make sure that you added the 'aws_iam_policy_document' data source to the configuratoin and try again. "
}
if ($policyDocument.expressions.statement.Count -eq 2) { 
    Write-Output "`u{2705} Checking number of policy document statements - OK. "
} else {
    throw "`u{1F635} Unable to validate number of policy document statements. Please make sure that you added 2 policy document statements and try again. "
}

$bucket_policy = $plan.configuration.root_module.resources | Where-Object {$_.type -eq "aws_s3_bucket_policy"}
if ($bucket_policy  -and ($bucket_policy.Count -eq 1 )) {
    Write-Output "`u{2705} Checking if bucket policy resource is present - OK. "
} else { 
    throw "`u{1F635} Unable to find bucket policy resource. Please make sure that you added the 'bucket_policy' data source to the configuratoin and try again. "
}

Write-Output ""
Write-Output "`u{1F973} Congratulations! All tests passed!"
