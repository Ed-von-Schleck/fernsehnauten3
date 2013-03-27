subscribePrograms = () ->
  @programsHandle = Meteor.subscribe "programs"
  inner = () =>
    console.log "triggered program update check"
    if @timer?
      Meteor.clearTimeout @timer
    now = +new Date / 1000 | 0
    Programs.find().forEach (program) ->
      if program.stop < now
        console.log "updating Programs subscription"
        @programsHandle.stop()
        @programsHandle = Meteor.subscribe "programs"
        @next = 5
      else
        if @next?
          @next = Math.min @next, program.stop
        else
          @next = program.stop
    if @next?
      console.log "set timeout to", (@next - now) * 1000, "(#{new Date(@next * 1000)})"
      @timer = Meteor.setTimeout inner, (@next - now) * 1000
      @next = undefined
    else
      console.log "retry in", 1000, "ms"
      @timer = Meteor.setTimeout inner, 1000
  inner()

Meteor.startup ->
  subscribePrograms()
