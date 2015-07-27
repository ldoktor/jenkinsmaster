<?xml version="1.0" encoding="UTF-8"?><project>
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
          <description>Don't run on nodes you don't own, they are shared with devels!</description>
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
    <!--TEMPLATE__FIRST_TASK__TEMPLATE--><hudson.tasks.Shell>
      <command>#!/bin/sh -xe
# GIT - Update repositories
AVOCADO_VT_PATH="$AVOCADO_PATH/../avocado-vt"
[ -d "$AUTOTEST_PATH" ] || git clone https://github.com/autotest/autotest.git "$AUTOTEST_PATH"
[ -d "$VIRT_TEST_PATH" ] || git clone https://github.com/autotest/virt-test.git "$VIRT_TEST_PATH"
[ -d "$AVOCADO_PATH" ] || git clone https://github.com/avocado-framework/avocado.git "$AVOCADO_PATH"
[ -d "$AVOCADO_VT_PATH" ] || git clone https://github.com/avocado-framework/avocado-vt.git "$AVOCADO_VT_PATH"
cd "$AUTOTEST_PATH" &amp;&amp; git checkout master &amp;&amp; git fetch --all &amp;&amp; git reset --hard origin/master
cd "$VIRT_TEST_PATH" &amp;&amp; git checkout master &amp;&amp; git fetch --all &amp;&amp; git reset --hard origin/master
cd "$AVOCADO_PATH" &amp;&amp; git checkout master &amp;&amp; git fetch --all &amp;&amp; git reset --hard origin/master
cd "$AVOCADO_VT_PATH" &amp;&amp; git checkout master &amp;&amp; git fetch --all &amp;&amp; git reset --hard origin/master</command>
    </hudson.tasks.Shell>
<!--TEMPLATE__PATCH__TEMPLATE-->
    <hudson.tasks.Shell>
      <command># AVOCADO - Instal dependences and change configuration
cd "$AVOCADO_PATH"
rpm -q PyYAML || yum install -y PyYAML
rpm -q tcpdump || yum install -y tcpdump
rpm -q genisoimage || yum install -y genisoimage
# pip install -r requirements.txt
make link
sed -i "s@^commands = /@commands = $AVOCADO_PATH/@g" etc/avocado/avocado.conf
sed -i "s@^files = /@files = $AVOCADO_PATH/@g" etc/avocado/avocado.conf
sed -i "s@^profilers = /@profilers = $AVOCADO_PATH/@g" etc/avocado/avocado.conf
sed -i "s/^skip_broken_plugin_notification =.*/skip_broken_plugin_notification = ['avocado.core.plugins.htmlresult', 'avocado.core.plugins.remote', 'avocado.core.plugins.vm']/g" etc/avocado/avocado.conf
sed -i "s/^arch =.*/arch = $ARCH/g" etc/avocado/conf.d/virt-test.conf
sed -i "s/^machine_type =.*/machine_type = $MACHINE/g" etc/avocado/conf.d/virt-test.conf
sed -i "s/^mem =.*/mem = 2048/g" etc/avocado/conf.d/virt-test.conf
sed -i "s/^sandbox =.*/sandbox = off/g" etc/avocado/conf.d/virt-test.conf
sed -i "s/^monitor =.*/monitor = qmp/g" etc/avocado/conf.d/virt-test.conf
sed -i "s@^qemu_bin =.*@qemu_bin = $QEMU@g" etc/avocado/conf.d/virt-test.conf
sed -i "s@^qemu_dst_bin =.*@qemu_dst_bin = $QEMU@g" etc/avocado/conf.d/virt-test.conf</command>
    </hudson.tasks.Shell>
    <hudson.tasks.Shell>
      <command># VIRT-TEST - Re-run bootstrap and update configuration
cd "$VIRT_TEST_PATH"
[ -d "$ISOS_PATH" ] || mkdir -p "$ISOS_PATH"
if [ ! -e "shared/data" ]; then
    if [ "$VIRT_TEST_DATA" ]; then
        mkdir -p "$VIRT_TEST_DATA" &amp;&amp; ln -s "$VIRT_TEST_DATA" "shared/data"
    else
        mkdir -p "shared/data"
    fi
    ln -s "$ISOS_PATH" "shared/data/isos"
fi
yes | ./run -t qemu --arch "$ARCH" -g RHEL.7.devel --no-download --qemu_sandbox=off --bootstrap
# migrate_vms breaks tests, remove this when it's fixed...
sed -i 's/^migrate_vms/#migrate_vms/g' backends/qemu/cfg/base.cfg</command>
    </hudson.tasks.Shell>
    <hudson.tasks.Shell>
      <command># Try executing simple avocado test to see it's usable
cd "$AVOCADO_PATH" &amp;&amp; ./scripts/avocado run passtest --vt-guest-os "$GUEST_OS"</command>
    </hudson.tasks.Shell>
  </builders>
  <publishers/>
  <buildWrappers>
    <hudson.plugins.ws__cleanup.PreBuildCleanup plugin="ws-cleanup@0.22">
      <deleteDirs>false</deleteDirs>
      <cleanupParameter/>
      <externalDelete/>
    </hudson.plugins.ws__cleanup.PreBuildCleanup>
  </buildWrappers>
</project>