<?xml version="1.0" encoding="UTF-8"?><project>
  <actions/>
  <description>Download the latest available RHEL ISO and install it.</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <jenkins.advancedqueue.AdvancedQueueSorterJobProperty plugin="PrioritySorter@2.8">
      <useJobPriority>false</useJobPriority>
      <priority>-1</priority>
    </jenkins.advancedqueue.AdvancedQueueSorterJobProperty>
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <org.jvnet.jenkins.plugins.nodelabelparameter.NodeParameterDefinition plugin="nodelabelparameter@1.5.1">
          <name>Chose node you registered through beaker</name>
          <description>Don't run on nodes you don't own, they are shared with devels!</description>
<!--TEMPLATE__MACHINES__TEMPLATE-->
          <triggerIfResult>multiSelectionDisallowed</triggerIfResult>
          <allowMultiNodeSelection>false</allowMultiNodeSelection>
          <triggerConcurrentBuilds>false</triggerConcurrentBuilds>
          <ignoreOfflineNodes>false</ignoreOfflineNodes>
          <nodeEligibility class="org.jvnet.jenkins.plugins.nodelabelparameter.node.AllNodeEligibility"/>
        </org.jvnet.jenkins.plugins.nodelabelparameter.NodeParameterDefinition>
        <hudson.model.StringParameterDefinition>
          <name>TESTS</name>
          <description>Don't change this unless you know what you're doing</description>
          <defaultValue>unattended_install.cdrom.extra_cdrom_ks.default_install.aio_threads boot</defaultValue>
        </hudson.model.StringParameterDefinition>
        <hudson.model.StringParameterDefinition>
          <name>CUSTOM_ISO</name>
          <description>Provide link to the full installation medium (DVD1) (by default <!--TEMPLATE__ISO_URL__TEMPLATE-->*RHEL*dvd*.iso)</description>
          <defaultValue/>
        </hudson.model.StringParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>
    <com.sonyericsson.rebuild.RebuildSettings plugin="rebuild@1.24">
      <autoRebuild>false</autoRebuild>
    </com.sonyericsson.rebuild.RebuildSettings>
    <hudson.plugins.throttleconcurrents.ThrottleJobProperty plugin="throttle-concurrents@1.8.3">
      <maxConcurrentPerNode>0</maxConcurrentPerNode>
      <maxConcurrentTotal>0</maxConcurrentTotal>
      <throttleEnabled>false</throttleEnabled>
      <throttleOption>project</throttleOption>
    </hudson.plugins.throttleconcurrents.ThrottleJobProperty>
    <hudson.plugins.disk__usage.DiskUsageProperty plugin="disk-usage@0.25"/>
  </properties>
  <scm class="hudson.scm.NullSCM"/>
  <canRoam>true</canRoam>
  <disabled>false</disabled>
  <blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>
  <blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>
  <triggers/>
  <concurrentBuild>false</concurrentBuild>
  <builders>
    <!--TEMPLATE__FIRST_TASK__TEMPLATE--><hudson.tasks.Shell>
      <command># Download latest ISO
<!--TEMPLATE__ISO_FIRST_LINE__TEMPLATE-->
if [ $CUSTOM_ISO ]; then
    LATEST=$(echo $CUSTOM_ISO | rev | cut -d/ -f1 | rev)
    URL=$(echo $CUSTOM_ISO | rev | cut -d/ -f2- | rev)
else
    URL="<!--TEMPLATE__ISO_URL__TEMPLATE-->"
    LATEST=`curl $URL | sed -n 's/.*&gt;\(RHEL.*dvd.*.iso\)&lt;.*/\1/p'`
fi
[ "$LATEST" ] || ( echo "Can't parse url of the latest RHEL iso"; exit 1 )
[ -e "$ISOS_PATH/$LATEST" ] &amp;&amp; echo "Already up to date, not downloading." || curl "$URL/$LATEST" -o "$ISOS_PATH/$LATEST"
[ -h "$ISOS_PATH/linux/RHEL-7-devel-<!--TEMPLATE__ISO_TAG__TEMPLATE-->.iso" ] || [ -e "$ISOS_PATH/linux/RHEL-7-devel-<!--TEMPLATE__ISO_TAG__TEMPLATE-->.iso" ] &amp;&amp; rm "$ISOS_PATH/linux/RHEL-7-devel-<!--TEMPLATE__ISO_TAG__TEMPLATE-->.iso"
[ -e "$ISOS_PATH/linux" ] || mkdir -p "$ISOS_PATH/linux"
ln -s "$ISOS_PATH/$LATEST" "$ISOS_PATH/linux/RHEL-7-devel-<!--TEMPLATE__ISO_TAG__TEMPLATE-->.iso"</command>
    </hudson.tasks.Shell>
    <hudson.tasks.Shell>
      <command># Run unattended install
cd "$AVOCADO_PATH"
./scripts/avocado run --xunit "$WORKSPACE/results.xml" --job-results-dir "$WORKSPACE" --vt-type qemu --vt-guest-os RHEL.7.devel <!--TEMPLATE__AVOCADO_EXTRA__TEMPLATE--> $TESTS</command>
    </hudson.tasks.Shell>
    <hudson.tasks.Shell>
      <command>#!/bin/sh -x
# Backup the images
for IMAGE in `ls "$VIRT_TEST_PATH"/shared/data/images/*.{qcow2,fd} 2&gt;/dev/null`; do
	cp "$IMAGE" "$VIRT_TEST_PATH/../" || exit 254
done</command>
    </hudson.tasks.Shell>
  </builders>
  <publishers>
    <hudson.tasks.ArtifactArchiver>
      <artifacts>latest/**/*</artifacts>
      <allowEmptyArchive>false</allowEmptyArchive>
      <onlyIfSuccessful>false</onlyIfSuccessful>
      <fingerprint>false</fingerprint>
      <defaultExcludes>true</defaultExcludes>
    </hudson.tasks.ArtifactArchiver>
  </publishers>
  <buildWrappers>
    <hudson.plugins.ws__cleanup.PreBuildCleanup plugin="ws-cleanup@0.22">
      <deleteDirs>false</deleteDirs>
      <cleanupParameter/>
      <externalDelete/>
    </hudson.plugins.ws__cleanup.PreBuildCleanup>
  </buildWrappers>
</project>