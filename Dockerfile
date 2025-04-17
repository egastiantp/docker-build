FROM registry.access.redhat.com/ubi8/ubi:latest

# Install Java 17 dan dependencies
ENV HOME=/root

RUN dnf install -y \
    unzip \
    git \
    && dnf clean all

RUN dnf install -y podman --setopt=install_weak_deps=False && dnf clean all

RUN mkdir -p /root/run/user/0
ENV XDG_RUNTIME_DIR=/root/run/user/0


RUN useradd -m -u 1001 -s /bin/bash jenkins

RUN git config --global http.sslVerify false \
    && git config --global user.name "jenkins" \
    && git config --global user.email "jenkins@bni.co.id"
   

COPY jdk-17.zip /tmp/
RUN unzip /tmp/jdk-17.zip -d /opt/ \
    && rm -f /tmp/jdk-17.zip \
    && ln -s /opt/jdk/jdk-17/bin/* /usr/local/bin/

ENV JAVA_HOME=/opt/jdk/jdk-17
ENV PATH="$JAVA_HOME/bin:$PATH"

# Konfigurasi Gradle agar menggunakan Java 17
RUN mkdir -p /home/jenkins/.gradle \
    && echo "org.gradle.java.home=$JAVA_HOME" >> /home/jenkins/.gradle/gradle.properties

# Copy dan install Gradle
COPY gradle-8.9-bin.zip /tmp/
RUN unzip /tmp/gradle-8.9-bin.zip -d /opt/ \
    && rm -f /tmp/gradle-8.9-bin.zip \
    && ln -s /opt/gradle-8.9/bin/gradle /usr/local/bin/gradle

# Copy Flyway ke dalam container
COPY flyway-commandline-11.4.0-linux-x64.tar.gz /tmp/

# Ekstrak dan pindahkan Flyway ke /opt/
RUN tar -xzf /tmp/flyway-commandline-11.4.0-linux-x64.tar.gz -C /opt/ \
    && mv /opt/flyway-* /opt/flyway \
    && rm -f /tmp/flyway-commandline-11.4.0-linux-x64.tar.gz

# Tambahkan Flyway ke PATH
RUN rm -rf /opt/flyway/jre

RUN sed -i 's|"$FLYWAY_HOME/jre/bin/java"|"/usr/lib/jvm/java-17-openjdk/bin/java"|' /opt/flyway/flyway
RUN chmod +x /opt/flyway/flyway

ENV PATH="/opt/flyway:$PATH"

# Copy file Sonar Scanner ke dalam container
COPY sonar-scanner-cli-7.0.2.4839-linux-x64.zip /tmp/

# Ekstrak dan pindahkan ke /opt/
RUN unzip /tmp/sonar-scanner-cli-7.0.2.4839-linux-x64.zip -d /opt/ \
    && mv /opt/sonar-scanner-* /opt/sonar-scanner \
    && rm -f /tmp/sonar-scanner-cli-7.0.2.4839-linux-x64.zip

RUN rm -rf /opt/sonar-scanner/jre

# Nonaktifkan penggunaan Java bawaan SonarScanner
RUN sed -i 's|use_embedded_jre=true|use_embedded_jre=false|' /opt/sonar-scanner/bin/sonar-scanner

# Tambahkan Sonar Scanner ke PATH
ENV PATH="/opt/sonar-scanner/bin:$PATH"

# Copy oc.tar ke dalam container
COPY oc.tar /tmp/

# Ekstrak ke dalam /opt/ dan beri permission
RUN tar -xvf /tmp/oc.tar -C /opt/ \
    && chmod +x /opt/oc \
    && ln -s /opt/oc /usr/local/bin/oc \
    && rm -f /tmp/oc.tar

RUN mkdir -p /home/jenkins/run/user/1001 && \
chown -R jenkins:jenkins /home/jenkins/run

RUN chown -R jenkins:jenkins /home/jenkins

USER jenkins
ENV HOME=/home/jenkins
ENV XDG_RUNTIME_DIR=/home/jenkins/run/user/1001

RUN git config --global http.sslVerify false \
    && git config --global user.name "jenkins" \
    && git config --global user.email "jenkins@bni.co.id"

# Set working directory
WORKDIR /home/jenkins

# Default command
CMD ["/bin/bash"]