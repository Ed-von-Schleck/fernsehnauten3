Template.feedback.events
  "click .selector_logo_container": (event) ->
    $target = $(event.currentTarget)
    channel_id = $target.attr "data-channel-id"
    
    if Meteor.userId()?
      query =
        _id: Meteor.userId()
      update =
        set: "profile.watching": channel_id
      Meteor.users.update query, update
