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
- **Docker CLI** - Container operations
- **Azure CLI** - Azure cloud operations
- **kubectl** - Kubernetes command-line tool
- **Helm** - Kubernetes package manager
- **yq** - YAML processor

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

## Supported Project Types

This agent image can handle:
- ✅ .NET Core / .NET 5+ applications
- ✅ .NET Framework applications (with Mono)
- ✅ Android applications (Java/Kotlin)
- ✅ Java applications
- ✅ Node.js / JavaScript applications
- ✅ Docker-based builds
- ✅ Kubernetes deployments
- ✅ Azure cloud deployments
