#!/bin/bash

# Pipeline Validation Script
# Validates all Azure DevOps pipelines and templates for syntax and best practices

set -euo pipefail

echo "=== Azure DevOps Pipeline Validation ==="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "OK")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}❌ $message${NC}"
            ;;
        *)
            echo "$message"
            ;;
    esac
}

# Function to validate YAML syntax
validate_yaml() {
    local file=$1
    if command -v yq &> /dev/null; then
        if yq eval '.' "$file" > /dev/null 2>&1; then
            print_status "OK" "YAML syntax valid: $file"
            return 0
        else
            print_status "ERROR" "YAML syntax error in: $file"
            return 1
        fi
    else
        print_status "WARNING" "yq not available, skipping YAML validation for: $file"
        return 0
    fi
}

# Function to check required fields in pipeline
validate_pipeline_structure() {
    local file=$1
    print_status "INFO" "Validating pipeline structure: $file"
    
    # Check for trigger configuration
    if grep -q "trigger:" "$file"; then
        print_status "OK" "Trigger configuration found"
    else
        print_status "WARNING" "No trigger configuration found"
    fi
    
    # Check for pool configuration
    if grep -q "pool:" "$file"; then
        print_status "OK" "Pool configuration found"
    else
        print_status "WARNING" "No pool configuration found"
    fi
    
    # Check for jobs or steps
    if grep -q "jobs:" "$file" || grep -q "steps:" "$file"; then
        print_status "OK" "Jobs or steps configuration found"
    else
        print_status "ERROR" "No jobs or steps configuration found"
    fi
}

# Function to validate template parameters
validate_template() {
    local file=$1
    print_status "INFO" "Validating template: $file"
    
    # Check for parameters section
    if grep -q "parameters:" "$file"; then
        print_status "OK" "Parameters section found"
        
        # Check parameter types
        if grep -A 10 "parameters:" "$file" | grep -q "type:"; then
            print_status "OK" "Parameter types defined"
        else
            print_status "WARNING" "Parameter types not defined"
        fi
        
        # Check for default values
        if grep -A 10 "parameters:" "$file" | grep -q "default:"; then
            print_status "OK" "Default values provided"
        else
            print_status "WARNING" "No default values for parameters"
        fi
    else
        print_status "WARNING" "No parameters section found (may be intended)"
    fi
    
    # Check for steps section
    if grep -q "steps:" "$file"; then
        print_status "OK" "Steps section found"
    else
        print_status "ERROR" "No steps section found in template"
    fi
}

# Function to check for security best practices
validate_security() {
    local file=$1
    print_status "INFO" "Checking security best practices: $file"
    
    # Check for hardcoded secrets (basic check)
    if grep -i "password\|secret\|token\|key" "$file" | grep -v "\$(.*)" | grep -v "secretRef" | grep -v "# " | grep -q .; then
        print_status "WARNING" "Potential hardcoded secrets found (review manually)"
    else
        print_status "OK" "No obvious hardcoded secrets found"
    fi
    
    # Check for privileged containers
    if grep -i "privileged.*true" "$file"; then
        print_status "WARNING" "Privileged containers detected"
    else
        print_status "OK" "No privileged containers found"
    fi
    
    # Check for runAsRoot
    if grep -i "runAsRoot.*true" "$file"; then
        print_status "WARNING" "Root execution detected"
    else
        print_status "OK" "No root execution found"
    fi
}

# Main validation function
validate_file() {
    local file=$1
    echo
    echo "--- Validating: $file ---"
    
    if [ ! -f "$file" ]; then
        print_status "ERROR" "File not found: $file"
        return 1
    fi
    
    # Validate YAML syntax
    validate_yaml "$file"
    
    # Determine file type and validate accordingly
    if [[ "$file" == *"template"* ]]; then
        validate_template "$file"
    else
        validate_pipeline_structure "$file"
    fi
    
    # Security validation for all files
    validate_security "$file"
}

# Main execution
echo "Starting pipeline validation..."
echo

# List of files to validate
pipeline_files=(
    "azure-pipelines.yml"
    "azure-pipelines-multi-env.yml"
    "azure-pipelines-security.yml"
)

template_files=(
    ".azuredevops/templates/build-and-push.yml"
    ".azuredevops/templates/deploy-helm-chart.yml"
)

# Validate main pipeline files
echo "=== Validating Main Pipeline Files ==="
for file in "${pipeline_files[@]}"; do
    if [ -f "$file" ]; then
        validate_file "$file"
    else
        print_status "WARNING" "Pipeline file not found: $file"
    fi
done

# Validate template files
echo
echo "=== Validating Template Files ==="
for file in "${template_files[@]}"; do
    if [ -f "$file" ]; then
        validate_file "$file"
    else
        print_status "WARNING" "Template file not found: $file"
    fi
done

# Validate environment values files
echo
echo "=== Validating Environment Values Files ==="
if [ -d "environments" ]; then
    for file in environments/*.yaml environments/*.yml; do
        if [ -f "$file" ]; then
            validate_yaml "$file"
        fi
    done
else
    print_status "WARNING" "No environments directory found"
fi

# Check for required tools
echo
echo "=== Checking Required Tools ==="
tools=("yq" "helm" "kubectl" "docker")
for tool in "${tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
        print_status "OK" "$tool is installed"
    else
        print_status "WARNING" "$tool is not installed"
    fi
done

echo
echo "=== Validation Complete ==="
echo
echo "Next steps:"
echo "1. Review any warnings or errors above"
echo "2. Test pipelines in a development environment"
echo "3. Verify all required variables are set in Azure DevOps"
echo "4. Ensure service connections are properly configured"
