<?xml version='1.0' encoding='UTF-8'?>
<project>
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
          <description>Don&apos;t run on nodes you don&apos;t own, they are shared with devels!</description>
<!--TEMPLATE__MACHINES__TEMPLATE-->
          <triggerIfResult>multiSelectionDisallowed</triggerIfResult>
          <allowMultiNodeSelection>false</allowMultiNodeSelection>
          <triggerConcurrentBuilds>false</triggerConcurrentBuilds>
          <ignoreOfflineNodes>false</ignoreOfflineNodes>
          <nodeEligibility class="org.jvnet.jenkins.plugins.nodelabelparameter.node.AllNodeEligibility"/>
        </org.jvnet.jenkins.plugins.nodelabelparameter.NodeParameterDefinition>
        <hudson.model.StringParameterDefinition>
          <name>TESTS</name>
          <description>Don&apos;t change this unless you know what you&apos;re doing</description>
          <defaultValue>unattended_install.cdrom.extra_cdrom_ks.default_install.aio_threads</defaultValue>
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
    <hudson.tasks.Shell>
      <command># Download latest ISO
<!--TEMPLATE__ISO_FIRST_LINE__TEMPLATE-->
URL=&quot;<!--TEMPLATE__ISO_URL__TEMPLATE-->&quot;
LATEST=`curl $URL | sed -n &apos;s/.*&gt;\(RHEL.*dvd.*.iso\)&lt;.*/\1/p&apos;`
[ &quot;$LATEST&quot; ] || ( echo &quot;Can&apos;t parse url of the latest RHELSA iso&quot;; exit 1 )
[ -e &quot;$ISOS_PATH/$LATEST&quot; ] &amp;&amp; echo &quot;Already up to date, not downloading.&quot; || curl &quot;$URL/$LATEST&quot; -o &quot;$ISOS_PATH/$LATEST&quot;
[ -h &quot;$ISOS_PATH/linux/RHEL-7-devel-<!--TEMPLATE__ISO_TAG__TEMPLATE-->.iso&quot; ] || [ -e &quot;$ISOS_PATH/linux/RHEL-7-devel-<!--TEMPLATE__ISO_TAG__TEMPLATE-->.iso&quot; ] &amp;&amp; rm &quot;$ISOS_PATH/linux/RHEL-7-devel-<!--TEMPLATE__ISO_TAG__TEMPLATE-->.iso&quot;
[ -e &quot;$ISOS_PATH/linux&quot; ] || mkdir -p &quot;$ISOS_PATH/linux&quot;
ln -s &quot;$ISOS_PATH/$LATEST&quot; &quot;$ISOS_PATH/linux/RHEL-7-devel-<!--TEMPLATE__ISO_TAG__TEMPLATE-->.iso&quot;</command>
    </hudson.tasks.Shell>
    <hudson.tasks.Shell>
      <command># Run unattended install
cd &quot;$AVOCADO_PATH&quot;
./scripts/avocado run --xunit &quot;$WORKSPACE/results.xml&quot; --job-results-dir &quot;$WORKSPACE&quot; --vt-type qemu --vt-guest-os RHEL.7.devel <!--TEMPLATE__AVOCADO_EXTRA__TEMPLATE--> $TESTS</command>
    </hudson.tasks.Shell>
    <hudson.tasks.Shell>
      <command>#!/bin/sh -x
# Backup the images
for IMAGE in `ls &quot;$VIRT_TEST_PATH&quot;/shared/data/images/*.{qcow2,fd} 2&gt;/dev/null`; do
	cp &quot;$IMAGE&quot; &quot;$VIRT_TEST_PATH/../&quot; || exit 254
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
      <cleanupParameter></cleanupParameter>
      <externalDelete></externalDelete>
    </hudson.plugins.ws__cleanup.PreBuildCleanup>
  </buildWrappers>
</project>
