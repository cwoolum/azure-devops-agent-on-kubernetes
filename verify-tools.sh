#!/bin/bash

echo "=== Verifying Build Tools Installation ==="
echo

# Check .NET Core
echo "Checking .NET Core SDK versions:"
dotnet --list-sdks || echo "❌ .NET Core not found"
echo

echo "Checking .NET Core runtime versions:"
dotnet --list-runtimes || echo "❌ .NET Core runtime not found"
echo

# Check Java
echo "Checking Java version:"
java -version || echo "❌ Java not found"
echo

echo "Checking JAVA_HOME:"
echo "JAVA_HOME: $JAVA_HOME"
echo

# Check Android SDK
echo "Checking Android SDK:"
echo "ANDROID_HOME: $ANDROID_HOME"
echo "ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT"
sdkmanager --list | head -20 || echo "❌ Android SDK not found"
echo

# Check Gradle
echo "Checking Gradle version:"
gradle --version || echo "❌ Gradle not found"
echo

# Check Maven
echo "Checking Maven version:"
mvn --version || echo "❌ Maven not found"
echo

# Check Node.js and npm
echo "Checking Node.js version:"
node --version || echo "❌ Node.js not found"
echo

echo "Checking npm version:"
npm --version || echo "❌ npm not found"
echo

# Check other essential tools
echo "Checking other essential tools:"
echo "Git: $(git --version)"
echo "Docker CLI: $(docker --version)"
echo "Azure CLI: $(az --version | head -1)"
echo "Kubectl: $(kubectl version --client --short 2>/dev/null || echo 'kubectl not found')"
echo "Helm: $(helm version --short 2>/dev/null || echo 'helm not found')"
echo "PowerShell: $(pwsh --version 2>/dev/null || echo 'PowerShell not found')"

echo
echo "=== Verification Complete ==="
