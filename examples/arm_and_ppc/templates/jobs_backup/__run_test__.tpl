<?xml version='1.0' encoding='UTF-8'?>
<project>
  <actions/>
  <description><!--TEMPLATE__DESCRIPTION__TEMPLATE--></description>
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
          <defaultValue><!--TEMPLATE__AVOCADO_TESTS__TEMPLATE--></defaultValue>
        </hudson.model.StringParameterDefinition>
        <hudson.model.StringParameterDefinition>
          <name>GUEST_OS</name>
          <description>Guest os for virt-test tests.</description>
          <defaultValue>RHEL.7.devel</defaultValue>
        </hudson.model.StringParameterDefinition>
        <hudson.model.StringParameterDefinition>
          <name>EXTRA_PARAMS</name>
          <description>Extra avocado params, eg: &quot;--vt-qemu-bin /usr/local/bin/qemu-system-x86_64&quot;</description>
          <defaultValue></defaultValue>
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
      <command>#!/bin/sh -x
cd &quot;$AVOCADO_PATH&quot; || exit 255
./scripts/avocado run $EXTRA_PARAMS --xunit &quot;$WORKSPACE/results.xml&quot; --job-results-dir &quot;$WORKSPACE&quot; --vt-type qemu --vt-guest-os $GUEST_OS <!--TEMPLATE__AVOCADO_EXTRA__TEMPLATE--> $TESTS
ERR=$?; [ $ERR -le 1 ] &amp;&amp; exit 0 || exit $ERR</command>
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
    <hudson.tasks.junit.JUnitResultArchiver plugin="junit@1.2-beta-4">
      <testResults>results.xml</testResults>
      <keepLongStdio>false</keepLongStdio>
      <testDataPublishers/>
      <healthScaleFactor>1.0</healthScaleFactor>
    </hudson.tasks.junit.JUnitResultArchiver>
  </publishers>
  <buildWrappers>
    <hudson.plugins.ws__cleanup.PreBuildCleanup plugin="ws-cleanup@0.22">
      <deleteDirs>false</deleteDirs>
      <cleanupParameter></cleanupParameter>
      <externalDelete></externalDelete>
    </hudson.plugins.ws__cleanup.PreBuildCleanup>
  </buildWrappers>
</project>
