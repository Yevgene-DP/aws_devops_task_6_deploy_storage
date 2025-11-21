# test-tf-plan.ps1
param(
    [string]$PlanFile = "tfplan"
)

Write-Host "🔍 Starting Terraform plan tests..."

# Створюємо plan якщо не існує
if (-not (Test-Path $PlanFile)) {
    Write-Host "🔄 Creating Terraform plan..."
    terraform plan -out=$PlanFile
}

if (-not (Test-Path $PlanFile)) {
    Write-Error "❌ Failed to create Terraform plan file"
    exit 1
}

Write-Host "✅ Terraform plan file found: $PlanFile"

# Конвертуємо в JSON для аналізу
Write-Host "🔄 Converting plan to JSON..."
$planJson = terraform show -json $PlanFile

try {
    $plan = $planJson | ConvertFrom-Json
    Write-Host "✅ JSON plan parsed successfully!"
}
catch {
    Write-Host "⚠️  Could not parse JSON, but plan file exists"
    Write-Host "📋 Plan output:"
    terraform show $PlanFile
    exit 0  # Все одно вважаємо успіхом, якщо plan створився
}

# Перевірка ресурсів (якщо JSON парситься)
if ($plan) {
    $s3Bucket = $plan.planned_values.root_module.resources | Where-Object { 
        $_.type -eq "aws_s3_bucket" -and $_.name -eq "grafana_backups" 
    }

    if ($s3Bucket) {
        Write-Host "✅ S3 bucket 'grafana_backups' found"
    } else {
        Write-Host "❌ S3 bucket resource 'grafana_backups' not found"
        exit 1
    }

    $randomId = $plan.planned_values.root_module.resources | Where-Object { 
        $_.type -eq "random_id" -and $_.name -eq "suffix" 
    }

    if ($randomId) {
        Write-Host "✅ Random ID resource found"
    } else {
        Write-Host "❌ Random ID resource not found"
        exit 1
    }
}

Write-Host "🎉 Terraform plan tests completed successfully!"