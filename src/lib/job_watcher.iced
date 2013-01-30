
JobStatus = 
  READY:    0
  RUNNING:  1
  COMPLETE: 2
  ERROR:    3
  INFO:     4


class Job
  constructor: (label) ->
    @label      = label
    @txt        = label
    @frac_done  = 0
    @status     = JobStatus.READY
    @lastChange = Date.now()

  update: (k,v) ->
    if not @[k]?
      throw new Error "JobWatcher doesn't understand #{k} = #{v}"
    @[k] = v
    @lastChange = Date.now()

class JobWatcher
  constructor: ->
    @jobs = {}

  update: (label, changes) ->
    if not @jobs[label]? then @jobs[label] = new Job label
    for k,v of changes
      @jobs[label].update k, v

  getInfo: (label) -> @jobs[label]

exports.JobWatcher = JobWatcher
exports.JobStatus  = JobStatus
