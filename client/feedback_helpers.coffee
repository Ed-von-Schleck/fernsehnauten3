Template.feedback.helpers
  channels: () ->
    return Channels.find()

  channel: (id) ->
    return Channels.findOne id
