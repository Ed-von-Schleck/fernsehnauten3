Template.improvement.helpers
  unknown_program: ->
    rand = Math.random()
    unknown_program = UnknownPrograms.findOne random: $gt: rand
    if not unknown_program?
      unknown_program = UnknownPrograms.findOne random: $lt: rand
    return unknown_program

  channel_names: (channel_ids) ->
    query =
      _id: $in: channel_ids
    options =
      fields:
        name: 1
    channels =  Channels.find query, options
    names = _.pluck channels.fetch(), "name"
    return names.join ", "
