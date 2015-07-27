<?xml version='1.0' encoding='UTF-8'?>
<project>
  <actions/>
  <description>Checkout the latest origin/master of Autotest, Virt-test and Avocado and reset the configuration.</description>
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
      <command>#!/bin/sh -e
# GIT - Update repositories
AVOCADO_VT_PATH=&quot;$AVOCADO_PATH/../avocado-vt&quot;
[ -d &quot;$AUTOTEST_PATH&quot; ] || git clone https://github.com/autotest/autotest.git &quot;$AUTOTEST_PATH&quot;
[ -d &quot;$VIRT_TEST_PATH&quot; ] || git clone https://github.com/autotest/virt-test.git &quot;$VIRT_TEST_PATH&quot;
[ -d &quot;$AVOCADO_PATH&quot; ] || git clone https://github.com/avocado-framework/avocado.git &quot;$AVOCADO_PATH&quot;
[ -d &quot;$AVOCADO_VT_PATH&quot; ] || git clone https://github.com/avocado-framework/avocado-vt.git &quot;$AVOCADO_VT_PATH&quot;
cd &quot;$AUTOTEST_PATH&quot; &amp;&amp; git checkout master &amp;&amp; git fetch --all &amp;&amp; git reset --hard origin/master
cd &quot;$VIRT_TEST_PATH&quot; &amp;&amp; git checkout master &amp;&amp; git fetch --all &amp;&amp; git reset --hard origin/master
cd &quot;$AVOCADO_PATH&quot; &amp;&amp; git checkout master &amp;&amp; git fetch --all &amp;&amp; git reset --hard origin/master
cd &quot;$AVOCADO_VT_PATH&quot; &amp;&amp; git checkout master &amp;&amp; git fetch --all &amp;&amp; git reset --hard origin/master</command>
    </hudson.tasks.Shell>
<!--TEMPLATE__PATCH__TEMPLATE-->
    <hudson.tasks.Shell>
      <command># AVOCADO - Instal dependences and change configuration
cd &quot;$AVOCADO_PATH&quot;
rpm -q PyYAML || yum install -y PyYAML
rpm -q tcpdump || yum install -y tcpdump
rpm -q genisoimage || yum install -y genisoimage
# pip install -r requirements.txt
make link
sed -i &quot;s@^commands = /@commands = $AVOCADO_PATH/@g&quot; etc/avocado/avocado.conf
sed -i &quot;s@^files = /@files = $AVOCADO_PATH/@g&quot; etc/avocado/avocado.conf
sed -i &quot;s@^profilers = /@profilers = $AVOCADO_PATH/@g&quot; etc/avocado/avocado.conf
sed -i &quot;s/^skip_broken_plugin_notification =.*/skip_broken_plugin_notification = [&apos;avocado.core.plugins.htmlresult&apos;, &apos;avocado.core.plugins.remote&apos;, &apos;avocado.core.plugins.vm&apos;]/g&quot; etc/avocado/avocado.conf
sed -i &quot;s/^arch =.*/arch = $ARCH/g&quot; etc/avocado/conf.d/virt-test.conf
sed -i &quot;s/^machine_type =.*/machine_type = $MACHINE/g&quot; etc/avocado/conf.d/virt-test.conf
sed -i &quot;s/^mem =.*/mem = 2048/g&quot; etc/avocado/conf.d/virt-test.conf
sed -i &quot;s/^sandbox =.*/sandbox = off/g&quot; etc/avocado/conf.d/virt-test.conf
sed -i &quot;s/^monitor =.*/monitor = qmp/g&quot; etc/avocado/conf.d/virt-test.conf
sed -i &quot;s@^qemu_bin =.*@qemu_bin = $QEMU@g&quot; etc/avocado/conf.d/virt-test.conf
sed -i &quot;s@^qemu_dst_bin =.*@qemu_dst_bin = $QEMU@g&quot; etc/avocado/conf.d/virt-test.conf</command>
    </hudson.tasks.Shell>
    <hudson.tasks.Shell>
      <command># VIRT-TEST - Re-run bootstrap and update configuration
cd &quot;$VIRT_TEST_PATH&quot;
[ -d &quot;$ISOS_PATH&quot; ] || mkdir -p &quot;$ISOS_PATH&quot;
[ -d &quot;shared/data&quot; ] || ( mkdir shared/data &amp;&amp; ln -s &quot;$ISOS_PATH&quot; shared/data/isos)
yes | ./run -t qemu --arch &quot;$ARCH&quot; -g RHEL.7.devel --no-download --qemu_sandbox=off --bootstrap
# migrate_vms breaks tests, remove this when it&apos;s fixed...
sed -i &apos;s/^migrate_vms/#migrate_vms/g&apos; backends/qemu/cfg/base.cfg</command>
    </hudson.tasks.Shell>
    <hudson.tasks.Shell>
      <command># Try executing simple avocado test to see it&apos;s usable
cd &quot;$AVOCADO_PATH&quot; &amp;&amp; ./scripts/avocado run passtest --vt-guest-os &quot;$GUEST_OS&quot;</command>
    </hudson.tasks.Shell>
  </builders>
  <publishers/>
  <buildWrappers>
    <hudson.plugins.ws__cleanup.PreBuildCleanup plugin="ws-cleanup@0.22">
      <deleteDirs>false</deleteDirs>
      <cleanupParameter></cleanupParameter>
      <externalDelete></externalDelete>
    </hudson.plugins.ws__cleanup.PreBuildCleanup>
  </buildWrappers>
</project>
