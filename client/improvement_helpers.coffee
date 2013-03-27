Template.improvement.helpers
  unknown_program: ->
    rand = Math.random()
    unknown_program = UnknownPrograms.findOne random: $gt: rand
    if not unknown_program?
      unknown_program = UnknownPrograms.findOne random: $lt: rand
    return unknown_program

  channel_name: (id) ->
    return Channels.findOne(id)?["display-name"][0][0]
