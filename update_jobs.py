#!/bin/env python
"""
This script creates multiple variants of jobs based on the templates form YAML
file
:author: Lukas Doktor <ldoktor@redhat.com>
:license: GPLv2
:copyright: Red Hat, Inc
"""

from collections import OrderedDict
import yaml
import re
import os
import glob
import pickle

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

VALUES = ordered_load(open("variants.yaml"))

def machines(machines):
    return ("<allowedSlaves>\n  <string>%s</string>\n</allowedSlaves>\n"
            "<defaultSlaves>\n  <string>%s</string>\n</defaultSlaves>"
            % ("</string>\n  <string>".join(machines), machines[0]))

def job(content, params, job_params):
    # Machines
    content = sub(content, "MACHINES", machines(params['MACHINES']))
    # Job_params
    for key, value in job_params.iteritems():
        content = sub(content, key, value)
    for key, value in params.get('__SHARED__', {}).iteritems():
        if key in job_params:
            continue
        content = sub(content, key, value, False)
    # Remove unused templates
    content = sub(content, r'.*', '', False)
    return content

def sub(string, key, value, mandatory=True):
    if isinstance(value, dict):
        if '__DATA__' in value:
            value = VALUES['data'][value['__DATA__']]
    string, count = re.subn("<!--TEMPLATE__%s__TEMPLATE-->" % key,
                            value, string)
    if mandatory and not count:
        raise ValueError("No TEMPLATE__%s__TEMPLATE found in template." % key)
    return string

def extends(params):
    def recursive_default(params, _params):
        for key, value in _params.iteritems():
            if key not in params:
                params[key] = value
            elif isinstance(value, dict):
                recursive_default(params[key], _params[key])
    _params = VALUES['variants'][params['__EXTENDS__']]
    if '__EXTENDS__' in _params:
        _params = extends(_params)
    recursive_default(params, _params)
    return params

def recreate():
    views = OrderedDict()      # Store all jobs for given variant
    # Update jobs
    for variant, params in VALUES['variants'].iteritems():
        if '__EXTENDS__' in params:
            params = extends(params)
        views[variant] = []
        print variant
        # Jobs from templates
        for name in [_.rsplit('.', 1)[0][15:]
                     for _ in glob.glob("templates/jobs/*")
                     if _[15:17] != "__"]:
            content = open("templates/jobs/%s.tpl" % name).read()
            print "  %s" % name
            try:
                content = job(content, params, params.get(name, {}))
            except ValueError, details:
                raise ValueError("Error occured while processing job '%s' of "
                                 "variant '%s': %s" % (name, variant, details))
            # Write the result file
            open("jobs/%s_%s.xml" % (name, variant), 'w').write(content)
            #views[variant].append("%s_%s.xml" % (name, variant))
            views[variant].append("%s_%s" % (name, variant))
        # Extra jobs
        for template, tvariants in VALUES['extra_jobs'].iteritems():
            template = open("templates/jobs/%s" % template).read()
            for name, tparams in tvariants.iteritems():
                print "  %s" % name
                try:
                    content = job(template, params, tparams)
                except ValueError, details:
                    raise ValueError("Error occured while processing job '%s' "
                                     "of variant '%s': %s"
                                     % (name, variant, details))
                open("jobs/%s_%s.xml" % (name, variant), 'w').write(content)
                views[variant].append("%s_%s" % (name, variant))

    # Store views for later processing
    pickle.dump(views, open("views.dump", "w"))


if __name__ == '__main__':
    recreate()
    os.system("meld .jobs jobs")
    os.system("meld .views/*.xml views/*.xml")
    if raw_input("Backup current jobs? (enter=>no, anychar+enter=yes):"):
        os.system("rm .jobs/*")
        os.system("mv jobs/* .jobs/")
