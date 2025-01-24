# Define an argument for the GCC version
ARG GCC_VERSION=13.3.0

# Builder stage: Installing and compiling GCC, with debugging and clarity 
FROM dockcross/manylinux2014-x64:latest AS builder
ARG GCC_VERSION

# Step 1: Install dependencies for GCC building
RUN yum update -y && \
    yum groupinstall -y "Development Tools" && \
    yum install -y \
    wget \
    tar \
    bzip2 \
    gcc \
    gcc-c++ \
    gmp-devel \
    mpfr-devel \
    libmpc-devel

# Step 2: Download and unpack GCC source
WORKDIR /opt
RUN wget https://ftp.nluug.nl/languages/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz && \
    tar -xzf gcc-${GCC_VERSION}.tar.gz 

# Step 3: Build GCC
WORKDIR /opt/gcc-${GCC_VERSION}
RUN ./contrib/download_prerequisites && \
    mkdir build && cd build && \
    # Configure only for the C++ language
    ../configure --disable-multilib --enable-languages=c++ --prefix=/opt/gcc-${GCC_VERSION} --disable-debug && \
    make -j$(nproc) && \
    make install && \
    # Strip binaries to reduce size
    strip --strip-all /opt/gcc-${GCC_VERSION}/bin/* && \
    find /opt/gcc-${GCC_VERSION} -name 'lib*.so*' -exec strip --strip-unneeded {} + && \
    # Remove static libraries and documentation
    find /opt/gcc-${GCC_VERSION} -name '*.a' -delete && \
    rm -rf /opt/gcc-${GCC_VERSION}/share/doc


# Final stage: assembling clean environment for runtime use with GCC
FROM dockcross/manylinux2014-x64:latest

ARG GCC_VERSION

# Step 4: Copy GCC binaries and libraries; ignore build dependencies
COPY --from=builder /opt/gcc-${GCC_VERSION} /opt/gcc-${GCC_VERSION}

# Set up GCC environment variables for proper paths in execution
ENV PATH="/opt/gcc-${GCC_VERSION}/bin:${PATH}"
ENV LD_LIBRARY_PATH="/opt/gcc-${GCC_VERSION}/lib64:${LD_LIBRARY_PATH}"
ENV CC=/opt/gcc-${GCC_VERSION}/bin/gcc
ENV CXX=/opt/gcc-${GCC_VERSION}/bin/g++
ENV LD=/opt/gcc-${GCC_VERSION}/bin/ld


