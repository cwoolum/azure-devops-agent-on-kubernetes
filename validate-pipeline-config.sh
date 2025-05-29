#!/bin/bash
# filepath: /workspaces/azure-devops-agent-on-kubernetes/validate-pipeline-config.sh
# Script to validate Azure DevOps pipeline configurations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    case $1 in
        "ERROR")   echo -e "${RED}❌ $2${NC}" ;;
        "SUCCESS") echo -e "${GREEN}✅ $2${NC}" ;;
        "WARNING") echo -e "${YELLOW}⚠️  $2${NC}" ;;
        "INFO")    echo -e "${BLUE}ℹ️  $2${NC}" ;;
    esac
}

# Function to check if a file exists
check_file() {
    if [ -f "$1" ]; then
        print_status "SUCCESS" "Found: $1"
        return 0
    else
        print_status "ERROR" "Missing: $1"
        return 1
    fi
}

# Function to validate YAML syntax
validate_yaml() {
    local file="$1"
    if command -v yq &> /dev/null; then
        if yq eval '.' "$file" > /dev/null 2>&1; then
            print_status "SUCCESS" "YAML syntax valid: $file"
            return 0
        else
            print_status "ERROR" "YAML syntax invalid: $file"
            return 1
        fi
    else
        print_status "WARNING" "yq not available, skipping YAML validation for $file"
        return 0
    fi
}

# Function to check pipeline structure
validate_pipeline_structure() {
    local file="$1"
    local errors=0
    
    print_status "INFO" "Validating pipeline structure: $file"
    
    # Check for required sections
    if ! grep -q "trigger:" "$file"; then
        print_status "WARNING" "No trigger section found in $file"
        ((errors++))
    fi
    
    if ! grep -q "stages:\|jobs:\|steps:" "$file"; then
        print_status "ERROR" "No stages, jobs, or steps section found in $file"
        ((errors++))
    fi
    
    # Check for Azure-specific tasks
    if grep -q "AzureCLI@2\|Docker@2\|KubernetesManifest@0" "$file"; then
        print_status "SUCCESS" "Azure DevOps tasks found in $file"
    fi
    
    return $errors
}

# Function to check template references
validate_template_references() {
    local file="$1"
    local errors=0
    
    print_status "INFO" "Checking template references in: $file"
    
    # Check if file contains template references
    if grep -q "template:" "$file"; then
        # Extract template references
        grep -o "template: [^[:space:]]*" "$file" | while read -r line; do
            template_path=$(echo "$line" | cut -d' ' -f2)
            if [ -f "$template_path" ]; then
                print_status "SUCCESS" "Template found: $template_path"
            else
                print_status "ERROR" "Template missing: $template_path"
                ((errors++))
            fi
        done
    else
        print_status "INFO" "No template references found in $file"
    fi
    
    return $errors
}

# Function to check environment files
validate_environment_files() {
    local errors=0
    
    print_status "INFO" "Validating environment configuration files"
    
    for env in dev staging prod; do
        env_file="environments/${env}-values.yaml"
        if check_file "$env_file"; then
            validate_yaml "$env_file"
        else
            ((errors++))
        fi
    done
    
    return $errors
}

# Function to check Docker and Helm files
validate_build_files() {
    local errors=0
    
    print_status "INFO" "Validating build files"
    
    # Check Dockerfile
    if check_file "Dockerfile"; then
        # Basic Dockerfile validation
        if grep -q "FROM" "Dockerfile"; then
            print_status "SUCCESS" "Dockerfile has FROM instruction"
        else
            print_status "ERROR" "Dockerfile missing FROM instruction"
            ((errors++))
        fi
    else
        ((errors++))
    fi
    
    # Check Helm chart
    if check_file "chart/Chart.yaml"; then
        validate_yaml "chart/Chart.yaml"
        
        # Check for required Helm chart fields
        if grep -q "name:" "chart/Chart.yaml" && grep -q "version:" "chart/Chart.yaml"; then
            print_status "SUCCESS" "Helm chart has required fields"
        else
            print_status "ERROR" "Helm chart missing required fields"
            ((errors++))
        fi
    else
        ((errors++))
    fi
    
    return $errors
}

# Function to check for security issues
check_security_issues() {
    local errors=0
    
    print_status "INFO" "Checking for potential security issues"
    
    # Check for hardcoded secrets (simple patterns)
    if grep -r -i "password\|secret\|token\|key" --include="*.yml" --include="*.yaml" . | grep -v "# filepath:" | grep -v "parameters:" | grep -v "variables:" > /dev/null; then
        print_status "WARNING" "Potential hardcoded secrets found - please review"
        grep -r -i "password\|secret\|token\|key" --include="*.yml" --include="*.yaml" . | grep -v "# filepath:" | grep -v "parameters:" | grep -v "variables:" | head -5
    fi
    
    # Check for proper Azure service connections
    if grep -r "azureSubscription:" --include="*.yml" --include="*.yaml" . | grep -q "Azure"; then
        print_status "WARNING" "Generic 'Azure' service connection found - consider using specific names"
    fi
    
    return $errors
}

# Main validation function
main() {
    print_status "INFO" "Starting Azure DevOps Pipeline Configuration Validation"
    echo
    
    local total_errors=0
    
    # List of pipeline files to validate
    pipeline_files=(
        "azure-pipelines.yml"
        "azure-pipelines-multi-env.yml"
        "azure-pipelines-security.yml"
        "azure-pipelines-advanced.yml"
    )
    
    # Template files to validate
    template_files=(
        ".azuredevops/templates/build-and-push.yml"
        ".azuredevops/templates/deploy-helm-chart.yml"
        ".azuredevops/templates/quality-gates.yml"
        ".azuredevops/templates/monitoring-setup.yml"
    )
    
    # Validate main pipeline files
    print_status "INFO" "=== Validating Pipeline Files ==="
    for file in "${pipeline_files[@]}"; do
        if [ -f "$file" ]; then
            validate_yaml "$file"
            validate_pipeline_structure "$file"
            validate_template_references "$file"
        else
            print_status "WARNING" "Pipeline file not found: $file"
        fi
        echo
    done
    
    # Validate template files
    print_status "INFO" "=== Validating Template Files ==="
    for file in "${template_files[@]}"; do
        if [ -f "$file" ]; then
            validate_yaml "$file"
        else
            print_status "WARNING" "Template file not found: $file"
        fi
    done
    echo
    
    # Validate environment files
    print_status "INFO" "=== Validating Environment Files ==="
    validate_environment_files
    echo
    
    # Validate build files
    print_status "INFO" "=== Validating Build Files ==="
    validate_build_files
    echo
    
    # Security checks
    print_status "INFO" "=== Security Checks ==="
    check_security_issues
    echo
    
    # Summary
    if [ $total_errors -eq 0 ]; then
        print_status "SUCCESS" "All validations passed! 🎉"
        echo
        print_status "INFO" "Pipeline configuration is ready for Azure DevOps"
    else
        print_status "ERROR" "Validation completed with $total_errors errors"
        echo
        print_status "INFO" "Please fix the errors before using the pipelines"
        exit 1
    fi
}

# Run main function
main "$@"
