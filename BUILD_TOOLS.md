# Build Tools and Development Environment Support

This Azure DevOps agent Docker image comes pre-installed with comprehensive build tools and development environments to support a wide variety of projects:

## .NET Core / .NET Development

- **.NET SDK 8.0** - Latest LTS version for modern .NET development
- **.NET SDK 6.0** - Previous LTS version for compatibility
- **PowerShell Core** - Cross-platform PowerShell for automation and scripting

### Usage Examples:
```bash
# Build a .NET project
dotnet build MyProject.csproj

# Run tests
dotnet test

# Publish application
dotnet publish -c Release -o ./publish
```

## Android / Mobile Development

- **Java 17 JDK** - Latest LTS Java version (default)
- **Java 11 JDK** - Alternative Java version for compatibility
- **Android SDK** - Complete Android development toolkit
  - Platform Tools (adb, fastboot)
  - Build Tools (multiple versions: 34.0.0, 33.0.2, 32.0.0, 31.0.0)
  - Android Platforms (API levels 31-34)
  - Support repositories
- **Gradle 8.5** - Modern build automation tool
- **Maven 3.9.6** - Alternative build tool for Java projects

### Environment Variables:
- `JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64`
- `ANDROID_HOME=/opt/android-sdk`
- `ANDROID_SDK_ROOT=/opt/android-sdk`
- `GRADLE_HOME=/opt/gradle`
- `MAVEN_HOME=/opt/maven`

### Usage Examples:
```bash
# Build Android project with Gradle
gradle assembleDebug

# Build with Maven
mvn clean install

# Android SDK manager operations
sdkmanager --list
sdkmanager "platforms;android-34"
```

## Additional Development Tools

- **Node.js 20.x** - JavaScript runtime for modern web development
- **npm** - Node package manager
- **Git** - Version control system
- **Docker Engine** - Complete Docker installation including:
  - Docker daemon
  - Docker CLI
  - Docker Buildx plugin
  - Docker Compose plugin
  - Standalone docker-compose
- **Azure CLI** - Azure cloud operations
- **kubectl** - Kubernetes command-line tool
- **Helm** - Kubernetes package manager
- **yq** - YAML processor

## Docker Support

The image includes a complete Docker installation that supports:
- Building Docker images
- Running containers
- Multi-stage builds with Docker Buildx
- Container orchestration with Docker Compose
- Docker-in-Docker scenarios (when properly configured)

### Kubernetes Docker Configuration

To enable Docker functionality in Kubernetes, you need to mount the Docker socket from the host. Update your Helm values:

```yaml
# values.yaml
volumes:
  - name: dockersock
    hostPath:
      path: /var/run/docker.sock

volumeMounts:
  - name: dockersock
    mountPath: "/var/run/docker.sock"
```

**Security Note**: Mounting the Docker socket gives the container root access to the host. Use with caution in production environments. Consider alternatives like:
- Kaniko for building images
- Buildah for rootless builds
- DinD (Docker-in-Docker) with proper security contexts

### Docker Usage Examples:
```bash
# Build a Docker image
docker build -t myapp:latest .

# Run a container
docker run -d --name myapp myapp:latest

# Use Docker Compose
docker-compose up -d

# Build multi-platform images with buildx
docker buildx build --platform linux/amd64,linux/arm64 -t myapp:latest .
```

## Tool Verification

To verify all tools are properly installed, you can run the included verification script:

```bash
./verify-tools.sh
```

This will check all installed development tools and display their versions.

## Build Pipeline Examples

### .NET Core Pipeline:
```yaml
steps:
- task: DotNetCoreCLI@2
  displayName: 'Restore packages'
  inputs:
    command: 'restore'
    projects: '**/*.csproj'

- task: DotNetCoreCLI@2
  displayName: 'Build project'
  inputs:
    command: 'build'
    projects: '**/*.csproj'
    arguments: '--configuration Release'
```

### Android Gradle Pipeline:
```yaml
steps:
- task: Gradle@2
  displayName: 'Build Android app'
  inputs:
    workingDirectory: ''
    gradleWrapperFile: 'gradlew'
    gradleOptions: '-Xmx3072m'
    tasks: 'assembleDebug'
```

### Docker Build Pipeline:
```yaml
steps:
- task: Docker@2
  displayName: 'Build and push Docker image'
  inputs:
    containerRegistry: 'myregistry'
    repository: 'myapp'
    command: 'buildAndPush'
    Dockerfile: '**/Dockerfile'
    tags: |
      $(Build.BuildId)
      latest

- script: |
    docker-compose -f docker-compose.test.yml up --abort-on-container-exit
  displayName: 'Run integration tests with Docker Compose'
```

## Supported Project Types

This agent image can handle:
- ✅ .NET Core / .NET 5+ applications
- ✅ .NET Framework applications (with Mono)
- ✅ Android applications (Java/Kotlin)
- ✅ Java applications
- ✅ Node.js / JavaScript applications
- ✅ Docker-based builds and deployments
- ✅ Multi-container applications with Docker Compose
- ✅ Container image builds with Docker Buildx
- ✅ Kubernetes deployments
- ✅ Azure cloud deployments
- ✅ Docker-in-Docker scenarios (with proper configuration)
