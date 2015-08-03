PYTHON=`which python`
DESTDIR=/
PROJECT=JenkinsMaster
VERSION=`cat $(CURDIR)/version`

source:
	$(PYTHON) setup.py sdist $(COMPILE) --dist-dir=SOURCES

install:
	$(PYTHON) setup.py install --root $(DESTDIR) $(COMPILE)

clean:
	$(PYTHON) setup.py clean
	rm -rf build/ SOURCES/ *.egg-info/
	find . -iname '*.pyc' -delete
