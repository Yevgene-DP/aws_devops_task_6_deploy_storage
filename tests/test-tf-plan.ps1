# test-tf-plan.ps1
param(
    [string]$PlanFile = "tfplan",
    [string]$JsonPlanFile = "tfplan.json"
)

Write-Host "🔍 Starting Terraform plan tests..."

# Перевірка наявності plan файлу
if (-not (Test-Path $PlanFile)) {
    Write-Error "❌ Terraform plan file '$PlanFile' not found."
    Write-Host "📁 Current directory: $(Get-Location)"
    Write-Host "📁 Files in directory:"
    Get-ChildItem
    exit 1
}

Write-Host "✅ Terraform plan file found: $PlanFile"

# Конвертуємо plan в JSON
Write-Host "🔄 Converting plan to JSON..."
terraform show -json $PlanFile > $JsonPlanFile

if (-not (Test-Path $JsonPlanFile)) {
    Write-Error "❌ Failed to create JSON plan file"
    exit 1
}

Write-Host "✅ JSON plan file created: $JsonPlanFile"

# Завантажуємо JSON
try {
    Write-Host "📖 Loading JSON plan..."
    $jsonContent = Get-Content -Path $JsonPlanFile -Raw -ErrorAction Stop
    $plan = $jsonContent | ConvertFrom-Json -ErrorAction Stop
    Write-Host "✅ JSON plan loaded successfully!"
}
catch {
    Write-Error "❌ Failed to parse JSON: $($_.Exception.Message)"
    Write-Host "💡 JSON content preview:"
    if (Test-Path $JsonPlanFile) {
        Get-Content -Path $JsonPlanFile -First 5
    }
    exit 1
}

# Перевірка ресурсів
Write-Host "🔍 Checking resources..."

$resourcesFound = @()
$resourcesMissing = @()

# S3 Bucket
$s3Bucket = $plan.planned_values.root_module.resources | Where-Object { 
    $_.type -eq "aws_s3_bucket" -and $_.name -eq "grafana_backups" 
}

if ($s3Bucket) {
    Write-Host "✅ S3 bucket 'grafana_backups' found"
    $resourcesFound += "S3 Bucket"
} else {
    Write-Error "❌ S3 bucket resource 'grafana_backups' not found"
    $resourcesMissing += "S3 Bucket"
}

# Random ID
$randomId = $plan.planned_values.root_module.resources | Where-Object { 
    $_.type -eq "random_id" -and $_.name -eq "suffix" 
}

if ($randomId) {
    Write-Host "✅ Random ID resource found"
    $resourcesFound += "Random ID"
} else {
    Write-Error "❌ Random ID resource not found"
    $resourcesMissing += "Random ID"
}

# Bucket Policy
$bucketPolicy = $plan.planned_values.root_module.resources | Where-Object { 
    $_.type -eq "aws_s3_bucket_policy" -and $_.name -eq "grafana_policy" 
}

if ($bucketPolicy) {
    Write-Host "✅ S3 bucket policy found"
    $resourcesFound += "Bucket Policy"
} else {
    Write-Error "❌ S3 bucket policy not found"
    $resourcesMissing += "Bucket Policy"
}

# Результати
Write-Host "`n📊 Test Results:"
Write-Host "✅ Found: $($resourcesFound -join ', ')"
if ($resourcesMissing) {
    Write-Error "❌ Missing: $($resourcesMissing -join ', ')"
    exit 1
}

Write-Host "🎉 All Terraform plan tests passed!"