# test-tf-plan.ps1
param(
    [string]$PlanFile = "tfplan"
)

# Перевірка наявності plan файлу
if (-not (Test-Path $PlanFile)) {
    Write-Error "❌ Terraform plan file '$PlanFile' not found."
    Write-Host "💡 Please run: terraform plan -out=$PlanFile"
    exit 1
}

Write-Host "✅ Testing Terraform plan..."

# Використовуємо terraform show для конвертації в JSON
$planJson = terraform show -json $PlanFile
$plan = $planJson | ConvertFrom-Json

Write-Host "✅ Plan file loaded successfully!"

# Перевірка наявності S3 bucket
$s3Bucket = $plan.planned_values.root_module.resources | Where-Object { 
    $_.type -eq "aws_s3_bucket" -and $_.name -eq "grafana_backups" 
}

if ($s3Bucket) {
    Write-Host "✅ S3 bucket 'grafana_backups' found in plan"
    Write-Host "   Bucket name: $($s3Bucket.values.bucket)"
} else {
    Write-Error "❌ S3 bucket resource 'grafana_backups' not found in plan"
    exit 1
}

# Перевірка наявності random_id
$randomId = $plan.planned_values.root_module.resources | Where-Object { 
    $_.type -eq "random_id" -and $_.name -eq "suffix" 
}

if ($randomId) {
    Write-Host "✅ Random ID resource found"
} else {
    Write-Error "❌ Random ID resource not found in plan"
    exit 1
}

# Перевірка наявності bucket policy
$bucketPolicy = $plan.planned_values.root_module.resources | Where-Object { 
    $_.type -eq "aws_s3_bucket_policy" -and $_.name -eq "grafana_policy" 
}

if ($bucketPolicy) {
    Write-Host "✅ S3 bucket policy found"
} else {
    Write-Error "❌ S3 bucket policy not found in plan"
    exit 1
}

Write-Host "🎉 All Terraform plan tests passed!"