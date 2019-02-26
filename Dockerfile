FROM jenkins/slave:3.26-1
USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        libicu57 \
        liblttng-ust0 \
        libssl1.0.2 \
        libstdc++6 \
        zlib1g \
        apt-transport-https \
        ca-certificates \
        software-properties-common \
    && rm -rf /var/lib/apt/lists/*

#Install DotnetCore SDK 2
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg
RUN mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/
RUN wget -q https://packages.microsoft.com/config/debian/9/prod.list
RUN mv prod.list /etc/apt/sources.list.d/microsoft-prod.list
RUN chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg
RUN chown root:root /etc/apt/sources.list.d/microsoft-prod.list
RUN apt-get update
RUN apt-get install -y dotnet-sdk-2.2

#Install Mono
RUN apt-get update -qq \
    && apt-key adv --no-tty --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
    && echo "deb https://download.mono-project.com/repo/debian stable-stretch main" | tee /etc/apt/sources.list.d/mono-official-stable.list \
    && apt-get update -qq \
    && apt-get install -y --no-install-recommends mono-complete \
        && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install software for GitVersion
RUN apt-get clean && apt-get update \
  && apt-get install -y --no-install-recommends unzip git libc6 libc6-dev libc6-dbg libgit2-24 \
  && rm -rf /var/lib/apt/lists/* /tmp/*

# Install GitVersion
RUN apt-get update && apt-get install -y unzip mono-runtime libmono-system-core4.0-cil libgit2-24 && \
    curl -L -o /tmp/GitVersion_4.0.0-beta0012.zip https://github.com/GitTools/GitVersion/releases/download/v4.0.0-beta.12/GitVersion_4.0.0-beta0012.zip && \
    unzip -d /opt/GitVersion /tmp/GitVersion_4.0.0-beta0012.zip && \
    rm /tmp/GitVersion_4.0.0-beta0012.zip && \
    echo '<configuration><dllmap os="linux" cpu="x86-64" wordsize="64" dll="git2-baa87df" target="/usr/lib/x86_64-linux-gnu/libgit2.so.24" /></configuration>' > \
    /opt/GitVersion/LibGit2Sharp.dll.config

RUN echo '#!/bin/bash\nexec mono /opt/GitVersion/GitVersion.exe "$@"' > /usr/bin/git-version
RUN chmod +x /usr/bin/git-version


#Install Docker
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
RUN apt-key fingerprint 0EBFCD88
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
RUN apt-get update
RUN apt-get -y install docker-ce

COPY jenkins-slave /usr/local/bin/jenkins-slave
RUN chmod 777 /usr/local/bin/jenkins-slave
ENTRYPOINT ["jenkins-slave"]
