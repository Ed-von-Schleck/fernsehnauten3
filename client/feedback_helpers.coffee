Template.feedback.helpers
  channels: () ->
    return Channels.find()

  channel: (id) ->
    return Channels.findOne id

  current_channel: ->
    channel_id = Meteor.user()?.profile?.watching
    if channel_id?
      return Channels.findOne channel_id
