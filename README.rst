##################################
Building and uploading pygrib_ wheels
##################################

We automate wheel building using this custom github repository that
builds on Github Actions (they provide x86 and x64 machines for Windows, Linux and Mac).

The Github Actions interface for the builds is
https://github.com/jswhit/pygrib-wheels/actions

The driving github repository is
https://github.com/jswhit/pygrib-wheels

How it works
============

The wheel-building repository:

* does a fresh build of any required C / C++ libraries;
* builds a pygrib_ wheel, linking against these fresh builds;
* processes the wheel using delocate_ (OSX) or auditwheel_ ``repair``
  (Manylinux1_).  ``delocate`` and ``auditwheel`` copy the required dynamic
  libraries into the wheel and relinks the extension modules against the
  copied libraries;
* uploads the built wheels to a pygrib-wheels github release.

The resulting wheels are self-contained and do not need any external
dynamic libraries apart from those provided as standard by OSX / Linux as
defined by the manylinux1 standard.


Triggering a build
==================

You will likely want to edit the ``build-wheels.yml`` and ``build-wheels-windows.yml`` files to
specify the ``BUILD_COMMIT`` before triggering a build - see below.

You will need write permission to the github repository to trigger new builds
on the travis-ci interface.  Contact us on the mailing list if you need this.

You can trigger a build by:

* making a commit to the ``pygrib-wheels`` repository (e.g. with ``git commit
  --allow-empty``); or
* clicking on the circular arrow icon towards the top right of the travis-ci
  page, to rerun the previous build.

In general, it is better to trigger a build with a commit, because this makes
a new set of build products and logs, keeping the old ones for reference.
Keeping the old build logs helps us keep track of previous problems and
successful builds.

Which pygrib commit does the repository build?
============================================

The ``pygrib-wheels`` repository will build the commit specified in the
``BUILD_COMMIT`` at the top of the ``.build-wheels.yml`` and ``build-wheels-windows.yml`` files.
This can be any naming of a commit, including branch name, tag name or commit
hash.

Uploading the built wheels to PyPI
==================================

When the wheels are updated, you can download them to your machine manually,
and then upload them manually to PyPI, or by using twine_.

.. _pygrib: https://github.com/jswhit/pygrib
.. _manylinux1: https://www.python.org/dev/peps/pep-0513
.. _twine: https://pypi.python.org/pypi/twine
.. _delocate: https://pypi.python.org/pypi/delocate
.. _auditwheel: https://pypi.python.org/pypi/auditwheel
