# Start with Ubuntu base image
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ARG GITHUB_TOKEN

# Install dependencies
RUN apt-get update && apt-get install -y \
    git wget curl python3 python3-pip unzip tar \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh \
    && bash miniconda.sh -b -p /opt/conda \
    && rm miniconda.sh
ENV PATH=/opt/conda/bin:$PATH

WORKDIR /iris
COPY . /iris/
RUN git clone https://github.com/iris-sast/cwe-bench-java.git data/cwe-bench-java

RUN chmod +x scripts/setup_environment.sh
RUN bash ./scripts/setup_environment.sh

# Set up shell
SHELL ["/bin/bash", "-c"]
#RUN echo "conda activate $(head -1 environment.yml | cut -d' ' -f2)" >> ~/.bashrc
RUN ENV_NAME=$(head -1 environment.yml | cut -d' ' -f2) && \
    conda init bash && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate $ENV_NAME" >> ~/.bashrc
# Copy JDKs from build context
COPY jdk-7u80-linux-x64.tar.gz jdk-8u202-linux-x64.tar.gz jdk-17.0.12_linux-x64_bin.tar.gz /iris/data/cwe-bench-java/java-env/
RUN cd /iris/data/cwe-bench-java/java-env/ && \
    tar xzf jdk-8u202-linux-x64.tar.gz --no-same-owner && \
    tar xzf jdk-7u80-linux-x64.tar.gz --no-same-owner && \
    tar xzf jdk-17.0.12_linux-x64_bin.tar.gz --no-same-owner && \
    chmod -R 755 */bin */lib && \
    chmod -R 755 */jre/bin */jre/lib && \
    rm *.tar.gz && \
    ls -la jdk-17.0.12/lib/libjli.so  # Verify the library exists and permissions
RUN rm -rf /iris/*.tar.gz
CMD ["/bin/bash"]