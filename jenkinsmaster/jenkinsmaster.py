#!/bin/env python

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# See LICENSE for more details.
#
# Copyright: Red Hat 2015
# Author: Lukas Doktor <ldoktor@redhat.com>


from argparse import ArgumentParser
from collections import OrderedDict
import glob
from itertools import izip
import logging
from md5 import md5
import os
import pickle
import re
import shutil

from jenkinsapi.jenkins import Jenkins
from jenkinsapi.utils.requester import Requester
from jenkinsapi.views import Views
import yaml


def ordered_load(stream, Loader=yaml.Loader):
    class OrderedLoader(Loader):
        pass

    def construct_mapping(loader, node):
        loader.flatten_mapping(node)
        return OrderedDict(loader.construct_pairs(node))

    OrderedLoader.add_constructor(
        yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG,
        construct_mapping)
    return yaml.load(stream, OrderedLoader)


class JenkinsMaster(object):

    def __init__(self):
        self.args = self._parse_args()
        level = ['DEBUG', 'INFO', 'WARN', 'ERROR'][min(3, self.args.debug)]
        logging.basicConfig(level=getattr(logging, level))
        self.log = logging.getLogger("app")
        self.config = ordered_load(open(self.args.config))
        self.basedir = os.path.dirname(self.args.config)
        requester = Requester(ssl_verify=False, baseurl=self.args.server)
        self.jenkins = Jenkins(self.args.server, requester=requester)

    def _push_job(self, name, xml):
        if name in self.jenkins.jobs:
            print "Update job: %s" % name
            job = self.jenkins.jobs[name].update_config(xml)
            assert not job, job
        else:
            print "Create job: %s" % name
            job = self.jenkins.create_job(name, xml)
            assert job is not None, job

    def _push_nested_view(self, name, subviews):
        if name in self.jenkins.views:
            print "Delete root view: %s" % name
            del(self.jenkins.views[name])
        print "Create root view: %s" % name
        root = self.jenkins.views.create(name, Views.NESTED_VIEW)
        assert root is not None, root

        for view, jobs in subviews.iteritems():
            print "  Create nested view: %s" % view
            view = root.views.create(view)
            assert view is not None, view
            for job in jobs:
                print "    Add job: %s" % job
                assert view.add_job(job)

    def _pull_jobs(self, location):
        xmls = sorted(glob.glob(os.path.join(os.path.abspath(location),
                                             '*.xml')))
        jobs = [os.path.basename(_)[:-4] for _ in xmls]
        remote_all = self.jenkins.jobs.keys()
        for name, xml in izip(jobs, xmls):
            if name in remote_all:
                job = self.jenkins.jobs[name]
                assert job is not None, job
                print "Job %s updated" % name
                open(xml, "w").write(job.get_config())
            else:
                print "Job %s removed" % name
                os.remove(xml)

    def _parse_args(self):
        parser = ArgumentParser(description="Jenkins master to manage your "
                                "Jenkins job/views")
        parser.add_argument("-d", "--debug", action="count", default=0,
                            help="Set the level of logging")
        parser.add_argument("-s", "--server", help="Set the jenkins server "
                            "address [http://localhost:8080]",
                            default="http://localhost:8080")
        parser.add_argument("config", help="Set the config file location "
                            "[./variants.yaml]", default="variants.yaml")
        return parser.parse_args()

    def run(self):
        def basename(job):
            return os.path.basename(job)[:-4]
        if raw_input("Pull jobs first? [no]"):
            self.pull_jobs()

        self.log.info("-" * 80)
        views = self.update_all_jobs()
        self.compare_jobs()
        self.log.info("-" * 80)
        if raw_input("Push changes? [no]"):
            changes = self.push_jobs()
            removed_jobs = [basename(job)
                            for job in glob.glob(os.path.join(self.basedir,
                                                              ".jobs", "*"))
                            if not os.path.exists(os.path.join(self.basedir,
                                                               "jobs",
                                                               basename(job) +
                                                               '.xml'))]
            if removed_jobs and raw_input("Remove deleted jobs? [no]"):
                changes += self.push_remove_jobs(removed_jobs)
                self.log.info("-" * 80)
            view = self.config['view']
            if changes and raw_input("Update views? [no]"):
                self.push_view(view, views)
            else:
                self.log.debug("Remote: view %s unchanged" % view)

    def compare_jobs(self):
        orig = os.path.join(self.basedir, ".jobs")
        new = os.path.join(self.basedir, "jobs")
        os.system("meld %s %s" % (orig, new))

    def pull_jobs(self):
        self._pull_jobs(os.path.join(self.basedir, ".jobs"))

    def update_all_jobs(self):
        per_view_jobs = OrderedDict()   # Stores jobs for given variant
        # Remove the old job xmls
        for name in glob.glob(os.path.join(self.basedir, "jobs", "*.xml")):
            os.remove(name)
        for view, params in self.config['views'].iteritems():
            if '__LONG_NAME__' in params:
                view_name = params['__LONG_NAME__']
            else:
                view_name = view
            # Jobs from views
            if '__EXTENDS__' in params:     # recursively extend values
                params = self._extends(self.config['views'], params)
            per_view_jobs[view_name] = self._update_jobs(view, params)
            # Extra jobs
        return per_view_jobs

    def _update_jobs(self, view, params):
        self.log.debug("  Processing view: %s", view)
        jobs = []
        for job, job_params in params.get('JOBS', {}).iteritems():
            self.log.debug("    Processing job: %s", job)
            if job in self.config['templates']:
                if job_params:
                    template_params = self.config['templates'][job].copy()
                    template_params.update(job_params)
                    job_params = template_params
                else:
                    job_params = self.config['templates'][job]
                template = os.path.join(self.basedir, "templates", "jobs",
                                        "%s.tpl" % job_params['__TEMPLATE__'])
                content = open(template).read()
            else:
                template = os.path.join(self.basedir, "templates", "jobs",
                                        "%s.tpl" % job)
                content = open(template).read()
            content = self._process_job(content, params, job_params)
            open(os.path.join(self.basedir, "jobs", "%s_%s.xml" % (job, view)),
                 'w').write(content)
            jobs.append("%s_%s" % (job, view))
        return jobs

    def _process_job(self, content, params, job_params):
        def machines(machines):
            return ("<allowedSlaves>\n"
                    "  <string>%s</string>\n"
                    "</allowedSlaves>\n"
                    "<defaultSlaves>\n"
                    "  <string>%s</string>\n"
                    "</defaultSlaves>"
                    % ("</string>\n  <string>".join(machines), machines[0]))

        if job_params is None:
            job_params = {}
        # First update MACHINES
        content = self._sub(content, "MACHINES", machines(params['MACHINES']))
        # Job params
        for key, value in job_params.iteritems():
            content = self._sub(content, key, value)
        for key, value in params.get('__SHARED__', {}).iteritems():
            if key in job_params:
                continue
            content = self._sub(content, key, value, False)
        # Remove unused templates
        content = self._sub(content, r'.*', '', False)
        return content

    def _sub(self, string, key, value, mandatory=True):
        if key[:2] == '__' and key[-2:] == '__':
            return string
        if isinstance(value, dict) and '__DATA__' in value:
            value = self.config['data'][value['__DATA__']]
        string, count = re.subn("<!--TEMPLATE__%s__TEMPLATE-->" % key,
                                value, string)
        if mandatory and not count:
            raise ValueError("No TEMPLATE__%s__TEMPLATE found in template."
                             % key)
        return string

    def _extends(self, root, params):
        def recursive_default(params, _params):
            for key, value in _params.iteritems():
                if key not in params:
                    params[key] = value
                elif isinstance(value, dict):
                    recursive_default(params[key], _params[key])
        _params = root[params['__EXTENDS__']]
        if '__EXTENDS__' in _params:
            _params = self._extends(root, _params)
        recursive_default(params, _params)
        return params

    def push_jobs(self):
        # Push all created jobs
        changes = 0
        for xml_path in glob.glob(os.path.join(self.basedir, "jobs", "*.xml")):
            name = os.path.basename(xml_path)[:-4]  # remove path + .xml
            _xml_path = os.path.join(self.basedir, ".jobs", "%s.xml" % name)
            if (os.path.exists(_xml_path) and
                    (md5(open(xml_path).read()).hexdigest() ==
                     md5(open(_xml_path).read()).hexdigest())):
                self.log.debug("Remote: job %s unchanged", name)
                continue
            self._push_job(name, open(xml_path).read())
            shutil.copy2(xml_path, _xml_path)
            changes += 1
        return changes

    def push_view(self, view, views):
        # Recreate the view and subviews
        self._push_nested_view(view, views)

    def push_remove_jobs(self, jobs):
        changes = 0
        for name in jobs:
            self.log.debug("Remote: deleting job %s", name)
            del(self.jenkins.jobs[name])
            os.remove(os.path.join(self.basedir, ".jobs", "%s.xml" % name))
            changes += 1
        return changes
