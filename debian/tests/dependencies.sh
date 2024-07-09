#!/bin/bash
set -o errexit
set -o errtrace
set -o pipefail
set -o nounset

host_arch="${DEB_HOST_ARCH:-$(dpkg --print-architecture)}"
jdk_path=$(echo /usr/lib/jvm/java-21-openjdk-amd64 | sed "s/-[^-]*$/-$host_arch/")


echo Check that PC/SC support can be loaded
cat <<EOF > ${AUTOPKGTEST_TMP}/Test.java
import java.util.List;
import javax.smartcardio.CardTerminal;
import javax.smartcardio.CardTerminals;
import javax.smartcardio.TerminalFactory;

public class Test {
    public static void main(String[] args ) throws Throwable {
        TerminalFactory factory = TerminalFactory.getDefault();
        List<CardTerminal> terminals = factory.terminals().list();
        System.out.println("Terminals: " + terminals);
    }
}
EOF

${jdk_path}/bin/java -Djava.security.debug=all \
    -cp . ${AUTOPKGTEST_TMP}/Test.java > ${AUTOPKGTEST_TMP}/dependencies-pcsc.log 2>&1

if grep "pcsc: Using PC/SC library" ${AUTOPKGTEST_TMP}/dependencies-pcsc.log; then
    echo "Test passed."
else
    cat ${AUTOPKGTEST_TMP}/dependencies-pcsc.log
    echo "PC/SC library can not be loaded"
    exit 1
fi
