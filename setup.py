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
"""
Python setup script
"""

from setuptools import setup, find_packages

version = open("VERSION", "r").read()

setup(name='jenkinsmaster',
      version=version,
      packages=['jenkinsmaster'],
      description='Jenkins job/views generator',
      long_description=open("README.md", 'r').read(),
      keywords = "jenkins deploy variants testing",
      author='Lukas Doktor',
      author_email='ldoktor@redhat.com',
      license='GPLv2',
      url='https://github.com/ldoktor/jenkinsmaster',
      install_requires=open("requires.txt", 'r').readlines(),
      scripts=['scripts/jenkinsmaster'],
     )

