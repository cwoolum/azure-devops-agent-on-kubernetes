# Azure DevOps Pipeline Architecture

This project uses a modular pipeline architecture with reusable templates to maintain consistency and reduce code duplication.

## Pipeline Files

### Main Pipelines
- **`azure-pipelines.yml`** - Simple single-stage pipeline for basic builds
- **`azure-pipelines-multi-env.yml`** - Multi-environment pipeline with dev/staging/prod stages
- **`azure-pipelines-security.yml`** - Security and compliance scanning pipeline
- **`azure-pipelines-advanced.yml`** - Enterprise-grade pipeline with advanced features

### Templates
- **`.azuredevops/templates/build-and-push.yml`** - Reusable template for building and pushing Docker images and Helm charts
- **`.azuredevops/templates/quality-gates.yml`** - Comprehensive quality assurance template
- **`.azuredevops/templates/monitoring-setup.yml`** - Monitoring and alerting configuration template

## Architecture Benefits

### 🔄 **Reusability**
- The `build-and-push.yml` template is used by both main pipelines
- Consistent build process across all environments
- Easy to maintain and update build logic in one place

### 🛡️ **Consistency**
- All pipelines use the same build steps
- Standardized security scanning and validation
- Uniform artifact generation and publishing

### 🎯 **Flexibility**
- Templates accept parameters for customization
- Different pipelines can enable/disable features (e.g., vulnerability scanning)
- Easy to create new pipelines for different scenarios

## Template Parameters

The `build-and-push.yml` template accepts these parameters:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `acrName` | string | `fanfindadmin` | Azure Container Registry name |
| `imageName` | string | `azure-devops-agent` | Docker image name |
| `imageTag` | string | `$(Build.BuildId)` | Docker image tag |
| `azureSubscription` | string | `Azure` | Azure service connection name |
| `chartPath` | string | `./chart` | Path to Helm chart directory |
| `runVulnerabilityScan` | boolean | `true` | Whether to run vulnerability scanning |
| `enableCaching` | boolean | `false` | Enable build caching |
| `runPerformanceTest` | boolean | `false` | Toggle performance baseline testing |
| `enablePrometheus` | boolean | `false` | Setup Prometheus monitoring |
| `enableLogging` | boolean | `false` | Configure log aggregation |

## Usage Examples

### Basic Pipeline Usage
```yaml
steps:
  - template: .azuredevops/templates/build-and-push.yml
    parameters:
      acrName: $(ACR_NAME)
      imageName: $(IMAGE_NAME)
      imageTag: $(IMAGE_TAG)
      azureSubscription: 'Azure'
      runVulnerabilityScan: true
```

### Custom Configuration
```yaml
steps:
  - template: .azuredevops/templates/build-and-push.yml
    parameters:
      acrName: 'myregistry'
      imageName: 'custom-agent'
      imageTag: 'v1.0.0'
      azureSubscription: 'Production'
      chartPath: './charts/agent'
      runVulnerabilityScan: false
      enableCaching: true
      runPerformanceTest: true
      enablePrometheus: true
      enableLogging: true
```

## Pipeline Selection Guide

Choose the appropriate pipeline based on your needs:

- **Use `azure-pipelines.yml`** for:
  - Simple CI/CD scenarios
  - Single environment deployments
  - Quick builds and testing

- **Use `azure-pipelines-multi-env.yml`** for:
  - Production environments
  - Multi-stage deployments
  - Controlled rollouts with approvals

- **Use `azure-pipelines-security.yml`** for:
  - Security compliance requirements
  - Regular security audits
  - Vulnerability assessments

- **Use `azure-pipelines-advanced.yml`** for:
  - Enterprise environments
  - Comprehensive quality gates
  - Performance testing
  - Full monitoring and alerting setup

## New Features and Enhancements

### 🚀 **Performance Optimizations**
- **Build Caching**: Docker layer and Helm dependency caching for faster builds
- **Parallel Execution**: Quality gates run in parallel with build processes where possible
- **Optimized Image Builds**: Multi-stage Dockerfile with build arguments and metadata

### 🛡️ **Enhanced Security**
- **Quality Gates Template**: Comprehensive security scanning including:
  - Secret detection with GitLeaks
  - Kubernetes security analysis with Checkov
  - Dockerfile security linting with Hadolint
- **Vulnerability Scanning**: Integrated Trivy scanning for container images
- **Security Compliance**: Automated security report generation

### 📊 **Monitoring and Observability**
- **Monitoring Setup Template**: Automated setup of:
  - Prometheus ServiceMonitor configuration
  - Grafana dashboard generation
  - Log aggregation with Fluent Bit
  - Health check monitoring with CronJobs
- **Alerting Rules**: Pre-configured alerts for:
  - Pod availability
  - High CPU/Memory usage
  - Application health status

### 🔧 **Quality Assurance**
- **Quality Gates**: Multi-layered validation including:
  - Code quality checks
  - Performance baseline testing
  - Integration testing
  - Post-deployment validation
- **Automated Testing**: Helm chart validation and Kubernetes manifest testing
- **Quality Reports**: Comprehensive reporting with artifact publishing

### 🏗️ **Advanced Pipeline Architecture**
- **Stage-based Deployment**: Progressive deployment through dev → staging → production
- **Conditional Logic**: Environment-specific deployment logic with branch-based triggers
- **Approval Gates**: Manual approval requirements for production deployments
- **Rollback Support**: Built-in rollback capabilities with Helm

## Template Enhancements

### Updated Templates
- **`build-and-push.yml`**: Added caching support and enhanced build validation
- **`deploy-helm-chart.yml`**: Integrated monitoring setup and health checks
- **`quality-gates.yml`**: New comprehensive quality assurance template
- **`monitoring-setup.yml`**: New monitoring and alerting configuration template

## Validation and Testing

### Pipeline Configuration Validator
A new script `validate-pipeline-config.sh` provides comprehensive validation:
- YAML syntax validation
- Pipeline structure verification
- Template reference checking
- Security issue detection
- Environment configuration validation

### Usage
```bash
./validate-pipeline-config.sh
```
