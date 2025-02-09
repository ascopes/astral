#!/usr/bin/env bash
# Bash will only allow returning 0 in a sourced script if outside a function.
# Note that ${BASH_SOURCE[0]} won't work in sourced scripts properly.
(return 0 2>/dev/null) || {
  echo "ERROR: please run this script as 'source \"${0}\"' rather than invoking it directly." >&2
  exit 1
}

export PATH="$(cd "$(dirname "$0")" && pwd)/out/bin:${PATH}"
