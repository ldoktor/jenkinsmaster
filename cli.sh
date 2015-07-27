#!/bin/sh
java -jar jenkins-cli.jar -noCertificateCheck -noKeyAuth -s https://localhost:8080/ $*
