#!/usr/bin/env bash
set -o errexit
set -o nounset
[[ -n ${DEBUG+defined} ]] && set -o xtrace

function container() {
  if docker --version > /dev/null 2>&1; then
    local command=(docker "${@}")
  elif podman --version > /dev/null 2>&1; then
    local command=(podman "${@}")
  else
    echo "ERROR: Cannot find docker or podman"
    return 2
  fi

  echo "Running ${command[@]}" >&2
  "${command[@]}"
}

function export_if_undefined() {
  local variable_name=$1
  local default_value=$2

  if [[ -z ${!variable_name+defined} ]]; then
    export "${variable_name}=${default_value}"
  fi
}

function make_shell_script() {
  echo "#!/usr/bin/env bash"
  echo "set -o errexit"
  echo "set -o nounset"
  if [[ -n ${DEBUG+defined} ]]; then
    echo "set -o xtrace"
  fi
  cat
}

function run_in_container() {
  local file_name; file_name=$(uuidgen)-$(date +%s).sh
  make_shell_script > "build/${file_name}"
  chmod +x "build/${file_name}"
  container run \
      --mount "type=bind,src=$(pwd),dst=/workspace" \
      --pid host \
      --rm \
      --tty \
      --user "$(id -u "${USER}"):$(id -g "${USER}")" \
      "${image_name}" \
      "build/${file_name}"
}

function usage() {
  echo "USAGE: ${BASH_SOURCE[0]} -a <arch> [-h]"
  echo "Build GCC, GDB, and Binutils for the given architecture."
  echo ""
  echo "Arguments:"
  echo "    -a <arch>   The architecture to target (e.g. i686-elf)."
  echo "    -h          Show this message, then exit."
  echo ""
  echo "Environment variables:"
  echo "    BINUTILS_VERSION    Override the version of Binutils to build."
  echo "    DEBUG               Define to run this script with debug logs."
  echo "    GCC_VERSION         Override the version of GCC to build."
  echo "    GDB_VERSION         Override the version of GDB to build."
  echo ""
}

while getopts ":a:h" opt; do
  case "${opt}" in
    a) readonly arch=${OPTARG} ;;
    h) usage; exit 0 ;;
    ?) echo "ERROR: Argument -${OPTARG} requires a value."; usage; exit 1 ;;
    :) echo "ERROR: Argument -${OPTARG} was not recognised."; usage; exit 1 ;;
  esac
done

for required_arg in arch; do
  if [[ -z ${!required_arg+defined} ]]; then
    echo "ERROR: Missing required argument '${required_arg}'."
    usage
    exit 1
  fi
done

export_if_undefined BINUTILS_VERSION 2.43
export_if_undefined GCC_VERSION 14.2.0
export_if_undefined GDB_VERSION 16.2

readonly image_name="gnu-toolchain:latest"
readonly binutils_url=https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz
readonly gcc_url=https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz
readonly gdb_url=https://ftp.gnu.org/gnu/gdb/gdb-${GDB_VERSION}.tar.gz

cd "$(dirname "${BASH_SOURCE[0]}")"

mkdir -pv src/ build/ out/

echo "Generating Dockerfile"
cat >> src/Dockerfile <<'EOF'
FROM public.ecr.aws/debian/debian:unstable-slim
RUN apt-get update \
    && apt-get install -qy \
        bash \
        bison \
        build-essential \
        curl \
        flex \
        gzip \
        libgmp3-dev \
        libisl-dev \
        libmpc-dev \
        libmpfr-dev \
        tar \
        texinfo \
    && chsh -s "$(which bash)" \
    && mkdir /workspace \
    && chmod -R a+rwx /workspace
WORKDIR /workspace
ENTRYPOINT ["/usr/bin/env", "bash"]
EOF

echo "Building container with build tools to generate the toolchain..."
container build . --file src/Dockerfile --tag "${image_name}"

run_in_container <<-EOF
  function dump_version() {
    echo
    echo "\$ \${@}"
    "\${@}"
    echo
    for i in {0..80}; do printf "%s" "-"; done
    echo
  }
  echo "Dumping build environment versions..."
  dump_version bash --version
  dump_version bison --version
  dump_version curl --version
  dump_version flex --version
  dump_version gzip --version
  dump_version gcc --version
  dump_version make --version
  dump_version tar --version
  dump_version uname -a
EOF

# Download resources.
run_in_container <<-EOF
  cd src
  for url in "${binutils_url}" "${gcc_url}" "${gdb_url}"; do
    echo "Downloading and extracting \${url}..."
    curl -L --fail-with-body "\${url}" | tar xz
  done
EOF

# Build binutils
run_in_container <<-EOF
  echo "Building binutils..."
  mkdir -pv build/binutils
  export PREFIX="\$(pwd)/out"
  export TARGET=${arch}
  export PATH="\$PREFIX/bin:\$PATH"
  cd build/binutils
  ../../src/binutils-${BINUTILS_VERSION}/configure \
      --target=${arch} \
      --prefix="\${PREFIX}" \
      --with-sysroot \
      --disable-nls \
      --disable-werror
  make -j $(($(nproc) * 2))
  make install
EOF

# Build gdb
run_in_container <<-EOF
  echo "Building gdb..."
  mkdir -pv build/gdb
  export PREFIX="\$(pwd)/out"
  export TARGET=${arch}
  export PATH="\$PREFIX/bin:\$PATH"
  cd build/gdb
  ../../src/gdb-${GDB_VERSION}/configure \
      --target=${arch} \
      --prefix="\${PREFIX}" \
      --disable-werror
  make -j $(($(nproc) * 2))
  make install
EOF

# Build gcc
run_in_container <<-EOF
  echo "Building gcc..."
  mkdir -pv build/gcc
  export PREFIX="\$(pwd)/out"
  export TARGET=${arch}
  export PATH="\$PREFIX/bin:\$PATH"
  cd build/gcc
  ../../src/gcc-${GCC_VERSION}/configure \
      --target=${arch} \
      --prefix="\${PREFIX}" \
      --disable-nls \
      --enable-languages=c,c++ \
      --without-headers \
      --disable-hosted-libstdcxx
  make -j $(($(nproc) * 2)) all-gcc all-target-libgcc all-target-libstdc++-v3
  make install-gcc install-target-libgcc install-target-libstdc++-v3
EOF
