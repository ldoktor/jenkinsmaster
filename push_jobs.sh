SERVER="http://localhost:8080/"
JENKINS="java -jar jenkins-cli.jar -noCertificateCheck -noKeyAuth -s ${SERVER}"

#function update_view {
#    VIEW="$*"
#    NAME="${VIEW:6:-4}"
#    #NAME=`echo $NAME | cut -d/ -f2`
#    if [ -e ".views/$NAME.xml" ]; then
#        echo "Updating view $NAME"
#        $JENKINS update-view "$NAME" < "$VIEW" || ERR_VIEWS+=" $NAME"
#    else
#        echo "Creating view $NAME"
#        $JENKINS create-view "$NAME" < "$VIEW" || ERR_VIEWS+=" $NAME"
#    fi
#}


ERR_JOBS=""
for JOB in jobs/*.xml; do
    NAME="${JOB:5:-4}"
    if [ -e ".jobs/$NAME.xml" ]; then
        echo "Updating $NAME"
        $JENKINS update-job $NAME < $JOB || ERR_JOBS+=" $NAME"
    else
        echo "Creating $NAME"
        $JENKINS create-job $NAME < $JOB || ERR_JOBS+=" $NAME"
    fi
done

#ERR_VIEWS=""
#for VIEW in views/*/*.xml; do
#    update_view $VIEW
#done

#for VIEW in views/*.xml; do
#    update_view $VIEW
#done

#[ "$ERR_JOBS" ] && echo "Fail to update jobs: $ERR_JOBS"
[ "$ERR_VIEWS" ] && echo "Fail to update views: $ERR_VIEWS"
