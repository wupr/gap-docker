FROM debian:bookworm-slim AS base

ENV GAP_VERSION=4.13.1
ENV GAP_INSTALL_DIR=/usr/local/gap

# Prevent APT from installing recommended or suggested packages
RUN cat > /etc/apt/apt.conf.d/99norecommend <<EOF
APT::Install-Recommends "0";
APT::Install-Suggests "0";
EOF

RUN apt-get update --quiet

# Add a user called `gap`
RUN adduser --disabled-password --gecos '' --uid 1000 gap


FROM base AS build

RUN mkdir "$GAP_INSTALL_DIR" && chown gap:gap "$GAP_INSTALL_DIR"

# Install dev dependencies
RUN apt-get install --quiet --yes build-essential autoconf
RUN apt-get install --quiet --yes libgmp-dev libreadline-dev zlib1g-dev
RUN apt-get install --quiet --yes 4ti2 pari-gp libncurses-dev libcdd-dev libcurl4-openssl-dev \
    libfplll-dev libmpc-dev libmpfi-dev libmpfr-dev singular libzmq3-dev

# Fetch the GAP release tarball
ADD "https://github.com/gap-system/gap/releases/download/v${GAP_VERSION}/gap-${GAP_VERSION}.tar.gz" \
    /home/gap
RUN chown gap:gap "/home/gap/gap-${GAP_VERSION}.tar.gz"

# Switch to the `gap` user and work in its home directory
USER gap
WORKDIR /home/gap
RUN tar --extract --gzip --file "gap-${GAP_VERSION}.tar.gz"

# Build GAP
WORKDIR "./gap-${GAP_VERSION}"
RUN ./configure --prefix="$GAP_INSTALL_DIR"
RUN make
RUN make install

# Build packages
WORKDIR ./pkg
RUN ../bin/BuildPackages.sh
# One can use the `MAKEFLAGS` variable to change the number of cores to use.
# E.g. `RUN MAKEFLAGS=-j8 ../bin/BuildPackages.sh` to use 8 cores.


FROM base AS out

# Install runtime dependencies
RUN apt-get install --quiet --yes libgmp10 libreadline8 zlib1g
RUN apt-get install --quiet --yes 4ti2 pari-gp libncurses5 libcdd0d libcurl4 \
    libfplll8 libmpc3 libmpfi0 libmpfr6 singular libzmq5

# Copy files from the `build` stage
COPY --from=build "$GAP_INSTALL_DIR" "$GAP_INSTALL_DIR"
COPY --from=build "/home/gap/gap-${GAP_VERSION}/pkg" "${GAP_INSTALL_DIR}/share/gap/pkg"

USER gap
WORKDIR /home/gap
ENV PATH="${GAP_INSTALL_DIR}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${GAP_INSTALL_DIR}/lib"
CMD ["bash"]
