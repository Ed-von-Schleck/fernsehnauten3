Meteor.publish "channels", ->
  query = {}
  options =
    fields:
      "display-name": 1
      "logo": 1
  return Channels.find query, options

Meteor.publish "programs", ->
  query =
    start: $lt: +new Date / 1000 | 0
    stop: $gt: +new Date / 1000 | 0
  options =
    fields:
      title: 1
      channel: 1
  return Programs.find query, options
