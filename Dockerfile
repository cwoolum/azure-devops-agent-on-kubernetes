ARG ARG_UBUNTU_BASE_IMAGE="ubuntu"
ARG ARG_UBUNTU_BASE_IMAGE_TAG="20.04"

FROM ${ARG_UBUNTU_BASE_IMAGE}:${ARG_UBUNTU_BASE_IMAGE_TAG}

# Build arguments for metadata
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
ARG ARG_TARGETARCH=linux-x64
ARG ARG_VSTS_AGENT_VERSION=4.251.0

# Add metadata labels
LABEL org.opencontainers.image.title="Azure DevOps Agent on Kubernetes" \
      org.opencontainers.image.description="Dockerized Azure DevOps build agent with comprehensive tooling support" \
      org.opencontainers.image.version="$VERSION" \
      org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.source="https://github.com/btungut/azure-devops-agent-on-kubernetes" \
      org.opencontainers.image.documentation="https://github.com/btungut/azure-devops-agent-on-kubernetes/blob/master/README.md" \
      org.opencontainers.image.vendor="Burak Tungut" \
      org.opencontainers.image.licenses="MIT" \
      maintainer="Burak Tungut <info@buraktungut.com>"

WORKDIR /azp


# To make it easier for build and release pipelines to run apt-get,
# configure apt to not require confirmation (assume the -y argument by default)
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes


# Install required tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    apt-utils \
    ca-certificates \
    curl \
    git \
    iputils-ping \
    jq \
    lsb-release \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get -y upgrade



# Download and extract the Azure DevOps Agent
RUN printenv \
    && echo "Downloading Azure DevOps Agent version ${ARG_VSTS_AGENT_VERSION} for ${ARG_TARGETARCH}"
RUN curl -LsS https://vstsagentpackage.azureedge.net/agent/${ARG_VSTS_AGENT_VERSION}/vsts-agent-${ARG_TARGETARCH}-${ARG_VSTS_AGENT_VERSION}.tar.gz | tar -xz



# Install Azure CLI & Azure DevOps extension
RUN curl -LsS https://aka.ms/InstallAzureCLIDeb | bash \
    && rm -rf /var/lib/apt/lists/*
RUN az extension add --name azure-devops



# Install required tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    unzip



# Install yq
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
    && mv ./yq_linux_amd64 /usr/bin/yq \
    && chmod +x /usr/bin/yq



# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash



# Install Kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && mv ./kubectl /usr/bin/kubectl \
    && chmod +x /usr/bin/kubectl



# Install Powershell Core
RUN wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" \
    && dpkg -i packages-microsoft-prod.deb
RUN apt-get update \
    && apt-get install -y powershell



# Install .NET Core SDK
RUN apt-get update \
    && apt-get install -y dotnet-sdk-8.0 dotnet-sdk-6.0 \
    && rm -rf /var/lib/apt/lists/*



# Install Java (required for Android builds)
RUN apt-get update \
    && apt-get install -y openjdk-17-jdk openjdk-11-jdk \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH



# Install Android SDK and tools
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=$ANDROID_HOME
ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools/bin

RUN mkdir -p $ANDROID_HOME/cmdline-tools \
    && wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    && unzip commandlinetools-linux-11076708_latest.zip -d $ANDROID_HOME/cmdline-tools \
    && mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest \
    && rm commandlinetools-linux-11076708_latest.zip

# Accept Android SDK licenses and install required components
RUN yes | sdkmanager --licenses \
    && sdkmanager "platform-tools" "platforms;android-34" "platforms;android-33" "platforms;android-32" "platforms;android-31" \
    && sdkmanager "build-tools;34.0.0" "build-tools;33.0.2" "build-tools;32.0.0" "build-tools;31.0.0" \
    && sdkmanager "extras;android;m2repository" "extras;google;m2repository"



# Install Gradle
ENV GRADLE_VERSION=8.5
RUN wget https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
    && unzip gradle-${GRADLE_VERSION}-bin.zip -d /opt \
    && rm gradle-${GRADLE_VERSION}-bin.zip \
    && ln -s /opt/gradle-${GRADLE_VERSION} /opt/gradle

ENV GRADLE_HOME=/opt/gradle
ENV PATH=$PATH:$GRADLE_HOME/bin



# Install Maven (alternative build tool for Java/Android projects)
ENV MAVEN_VERSION=3.9.6
RUN wget https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    && tar -xzf apache-maven-${MAVEN_VERSION}-bin.tar.gz -C /opt \
    && rm apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    && ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven

ENV MAVEN_HOME=/opt/maven
ENV PATH=$PATH:$MAVEN_HOME/bin



# Install Node.js and npm (often needed for modern mobile development)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs



# Install Docker Engine (full Docker installation)
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Install Docker Compose (standalone) for compatibility
RUN curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose



# do apt-get upgrade
RUN apt-get update && apt-get -y upgrade



# Copy start script
COPY ./start.sh .
RUN chmod +x start.sh



# Create non-root user under docker group
RUN useradd -m -s /bin/bash -u "1000" azdouser
RUN groupadd docker || true && usermod -aG docker azdouser
RUN apt-get update \
    && apt-get install -y sudo \
    && echo azdouser ALL=\(root\) NOPASSWD:ALL >> /etc/sudoers

RUN sudo chown -R azdouser /home/azdouser
RUN sudo chown -R azdouser /azp
RUN sudo chown -R azdouser /var/run/docker.sock || true
RUN sudo chown -R azdouser /opt/android-sdk || true
RUN sudo chown -R azdouser /opt/gradle || true
RUN sudo chown -R azdouser /opt/maven || true
USER azdouser


# cd to /azp and run start.sh
WORKDIR /azp
ENTRYPOINT ["./start.sh"]
