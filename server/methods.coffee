Meteor.methods
  like: (program_id, program_title) ->
    return if not @userId?
    query =
      _id: @userId
      "profile.history": $ne: program_id
    update =
      $push:
        "profile.hot_programs":
          title: program_title
          counter: 0
    Meteor.users.update query, update

    query =
      _id: @userId
      "profile.hot_programs.title": program_title
    update =
      $push:
        "profile.history": program_id
      $inc:
        "profile.hot_programs.$.counter": 1
    Meteor.users.update query, update

    user = Meteor.users.findOne @userId
    size = user.profile.history.length
    if Relations.find(user_ids: @userId).count() is 0
      console.log "triggered addRandomEdge for", @userId
      addRandomEdge @userId
    logSize = Math.log(size) / Math.log(2)
    if logSize is (logSize | 0) # 0, 1, 2, 4, 8, ... 2^n
      console.log "triggered walk for", @userId
      walk @userId
