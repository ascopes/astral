#!/usr/bin/env bash
###
### Script to build a GNU cross-compiler to build this project.
###
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

function dedent() {
  sed -E 's/^ {'$1'}//g'
}

function export_if_undefined() {
  local variable_name=$1
  local default_value=$2

  if [[ -z ${!variable_name+defined} ]]; then
    export "${variable_name}=${default_value}"
  fi
}

function is_tool_enabled() {
  local expected_tool=${1}

  if [[ -z ${tools[@]+defined} ]]; then
    return 0
  fi

  for tool in "${tools[@]}"; do
    if [[ ${tool} = ${expected_tool} ]]; then
      return 0
    fi
  done

  return 1
}

function make_shell_script() {
  echo "#!/usr/bin/env bash"
  echo "set -o errexit"
  echo "set -o nounset"
  echo "set -o xtrace"
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
  echo "USAGE: ${BASH_SOURCE[0]} -a <arch> [-h] [ { -t <tool> } ]"
  echo "Build a GNU-based cross-compiler suite for the given architecture."
  echo ""
  echo "Arguments:"
  echo "    -a <arch>   The architecture to target (e.g. i686-elf)."
  echo "    -h          Show this message, then exit."
  echo "    -t <tool>   The tools to build (repeatable, excluding this will run all tools)."
  echo ""
  echo "Environment variables:"
  echo "    BINUTILS_VERSION    Override the version of Binutils to build."
  echo "    DEBUG               Define to run this script with debug logs."
  echo "    GCC_VERSION         Override the version of GCC to build."
  echo "    GDB_VERSION         Override the version of GDB to build."
  echo ""
}

tools=()

while getopts ":a:ht:" opt; do
  case "${opt}" in
    a) readonly arch=${OPTARG} ;;
    h) usage; exit 0 ;;
    t) tools+=("${OPTARG}") ;;
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

function build_container() {
  echo "Generating Dockerfile"
  dedent 4 > src/Dockerfile <<'EOF'
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
        && echo "Installing stuff for GRUB specifically..." \
        && apt-get install -qy \
            automake \
            autoconf \
            autopoint \
            gawk \
            gettext \
            git \
            libtool \
            m4 \
            pkg-config \
            python3 \
            python3-pip \
        && chsh -s "$(which bash)" \
        && mkdir /workspace \
        && chmod -R a+rwx /workspace
    WORKDIR /workspace
    ENTRYPOINT ["/usr/bin/env", "bash"]
EOF

  echo "Building container with build tools to generate the toolchain..."
  container build . --file src/Dockerfile --tag "${image_name}"
}

function build_binutils() {
  dedent 4 <<-EOF | run_in_container 
    if ! [[ -d "src/binutils-${BINUTILS_VERSION}" ]]; then
      cd src/
      echo "Downloading binutils..."
      curl -L --fail-with-body "${binutils_url}" | tar xz
      cd ..
    fi

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
    make -j $(($(nproc) * 4))
    make install
EOF
}

function build_gcc() {
  # Download gcc dependencies
  dedent 4 <<-EOF | run_in_container 
    if ! [[ -d "src/gcc-${GCC_VERSION}" ]]; then
      cd src/
      echo "Downloading gcc..."
      curl -L --fail-with-body "${gcc_url}" | tar xz
      echo "Downloading gcc dependencies..."
      cd gcc-${GCC_VERSION}
      contrib/download_prerequisites
      cd ../..
    fi

    # Inject patches for GCC to compile without the redzone in libgcc for
    # x86_64 builds.

    echo "Injecting workaround to disable the red zone on x86_64-elf..."
    {
      echo "# Add libgcc multilib variant without red-zone requirement"
      echo "MULTILIB_OPTIONS += mno-red-zone"
      echo "MULTILIB_DIRNAMES += no-red-zone"
    } > src/gcc-${GCC_VERSION}/gcc/config/i386/t-x86_64-elf
    if [[ -f "src/gcc-${GCC_VERSION}/gcc/config.gcc.orig" ]]; then
      # Revert to original first if we detect we've already patched this file before.
      cp -v src/gcc-${GCC_VERSION}/gcc/config.gcc.orig src/gcc-${GCC_VERSION}/gcc/config.gcc
    fi
    patch -biN --verbose src/gcc-${GCC_VERSION}/gcc/config.gcc gcc-x86_64-elf-redzone.patch

    # Build gcc

    echo "Building gcc..."
    mkdir -pv build/gcc
    export PREFIX="\$(pwd)/out"
    export TARGET=${arch}
    export PATH="\$PREFIX/bin:\$PATH"

    cd build/gcc

    echo "Compiling GCC."
    ../../src/gcc-${GCC_VERSION}/configure \
        --target=${arch} \
        --prefix="\${PREFIX}" \
        --disable-multilib \
        --disable-nls \
        --enable-languages=c,c++ \
        --without-headers \
        --disable-hosted-libstdcxx \
        --disable-werror
    make -j $(($(nproc) * 4)) all-gcc all-target-libgcc all-target-libstdc++-v3
    make install-gcc install-target-libgcc install-target-libstdc++-v3
EOF
}

function build_gdb() {
  dedent 4 <<-EOF | run_in_container 
    if ! [[ -d "src/gdb-${GDB_VERSION}" ]]; then
      cd src/
      echo "Downloading gdb..."
      curl -L --fail-with-body "${gdb_url}" | tar xz
      cd ..
    fi

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
    make -j $(($(nproc) * 4))
    make install
EOF
}

build_container
is_tool_enabled "binutils" && build_binutils
is_tool_enabled "gcc" && build_gcc
is_tool_enabled "gdb" && build_gdb
