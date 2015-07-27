IFS=$(echo -en "\n\b")
SERVER="https://localhost:8080/"
JENKINS=`echo -ne "java${IFS}-jar${IFS}jenkins-cli.jar${IFS}-noCertificateCheck${IFS}-noKeyAuth${IFS}-s${IFS}${SERVER}"`
for AAA in `$JENKINS list-jobs`; do
    echo $AAA
    $JENKINS get-job $AAA > backup_jobs/$AAA.xml
    sed -i -n '/<?xml/,$p' backup_jobs/$AAA.xml
done
