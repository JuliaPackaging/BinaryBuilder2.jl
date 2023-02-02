Useful features I want to add before I call this rewrite "done":

* Parallel/much faster Auditor
* Shared read-only depot that we can "compact" compiler shards and whatnot into (perhaps this should be a buildkite plugin?)
* Create torture-test-suite to run a bunch of builds in parallel on a new depot, to make sure that we can share resources properly


Things that would be nice to have, but we don't _need_:
* LRU cache of specific size for `downloads` folder
