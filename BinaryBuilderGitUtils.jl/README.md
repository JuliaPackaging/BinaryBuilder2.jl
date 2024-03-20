# BinaryBuilderGitUtils.jl

A collection of utilities for working with git repositories.
These functions are used in two main places in the BinaryBuilder workflow:

* First, for `GitSource`s during builds.  In this scenario, the typical workflow is that a bare clone is setup in BB's cache, and then various commits are checked out from that bare clone to temporary working directories for a build.
* Second, for committing and pushing new JLL versions.  In this scenario, the bare clone is checked out, modified, committed, then eventually pushed back up to the remote on GitHub.

This package is purposefully not comprehensive.
It is intended to encompass the minimal set of features necessary for BinaryBuilder to work with the `git` CLI, and no more.
