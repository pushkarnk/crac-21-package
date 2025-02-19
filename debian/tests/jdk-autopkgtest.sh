#!/bin/bash
set -o errexit
set -o errtrace
set -o pipefail
set -o nounset

host_arch="${DEB_HOST_ARCH:-$(dpkg --print-architecture)}"
jdk_path=$(echo /usr/lib/jvm/java-21-openjdk-amd64 | sed "s/-[^-]*$/-$host_arch/")

if ! $jdk_path/bin/java -version 2>/dev/null; then
    echo >&2 "error: $jdk_path/bin/java not found"
    exit 1
fi

if $jdk_path/bin/java -version 2>/dev/null | grep -F --quiet Zero ; then
    echo >&2 "skipping tests with the Zero interpreter"
    exit 77
fi

cleanup() {
  # kill window manager to clean up (rest will exit automatically)
  pid="$(jobs -p)"
  if [ -n "$pid" ]; then
      xvfbpid="$(pgrep -l -P ${pid} | grep xvfb-run | cut -d' ' -f1)"
      if [ -n "$xvfbpid" ]; then
        pgrep -l -P ${xvfbpid} | grep xfwm4 | cut -d' ' -f1 | xargs kill -9
      fi
  fi
}

for sig in INT QUIT HUP TERM; do trap "cleanup; trap - $sig EXIT; kill -s $sig "'"$$"' "$sig"; done
trap cleanup EXIT

export HOME="${AUTOPKGTEST_TMP}"
export XAUTHORITY="${AUTOPKGTEST_TMP}/.Xauthority"
export DISPLAY=:10
debian/tests/start-xvfb.sh 10 &
sleep 3

JDK_JTREG_PATH=test/jdk
JDK_JTREG_NATIVE_PATH=${jdk_path}/testsuite/jdk/jtreg/native

problem_list=${AUTOPKGTEST_TMP}/problems.txt

debian/tests/write-problems ${problem_list} ${JDK_JTREG_PATH}/ProblemList.txt jdk

ARGS="$*"
JT_DEFAULT_ARGS="-exclude:${problem_list} -k:!stress :tier1"
JT_ARGS=${ARGS:-$JT_DEFAULT_ARGS}

debian/tests/jtreg-autopkgtest.sh jdk \
  -dir:${JDK_JTREG_PATH} \
  -nativepath:${JDK_JTREG_NATIVE_PATH} \
  $JT_ARGS
