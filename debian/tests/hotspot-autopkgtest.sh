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

HOTSPOT_JTREG_PATH=test/hotspot/jtreg
HOTSPOT_JTREG_NATIVE_PATH=${jdk_path}/testsuite/hotspot/jtreg/native

problem_list=${AUTOPKGTEST_TMP}/problems.txt
debian/tests/write-problems ${problem_list} ${HOTSPOT_JTREG_PATH}/ProblemList.txt hotspot

ARGS="$*"
JT_DEFAULT_ARGS="-exclude:${problem_list} -k:!stress :tier1"
JT_ARGS=${ARGS:-$JT_DEFAULT_ARGS}

debian/tests/jtreg-autopkgtest.sh hotspot \
    -dir:${HOTSPOT_JTREG_PATH} \
    -nativepath:${HOTSPOT_JTREG_NATIVE_PATH} \
    $JT_ARGS
