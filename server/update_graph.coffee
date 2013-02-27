addRandomEdge = (userId) ->
  user = Meteor.users.findOne userId
  return if not user?
  return if not user.profile.hot_programs?
  query =
    _id: $ne: userId
  options =
    limit = 100
  Meteor.users.find(_id: $ne: userId).forEach (otherUser) ->
    console.log "  checking", otherUser._id
    if not Relations.findOne(user_ids: $all: [otherUser._id, userId])?
      strength = calculateWeight user, otherUser
      if strength?
        upsertRelation userId, otherUser._id, strength

upsertRelation = (userId, otherUserId, strength) ->
    existingRelation = Relations.findOne
      user_ids:
        $all: [userId, otherUserId]

    if strength >= 0.5
      if existingRelation?
        if existingRelation.weight isnt strength
          console.log "updating Relation between", userId, "and", otherUserId, "to weight", strength
          Relations.update {_id: existingRelation._id}, {$set: weight: strength}
      else
        console.log "inserting Relation between", userId, "and", otherUserId, "with weight", strength
        Relations.insert
          user_ids: [userId, otherUserId]
          weight: strength
    else
      if existingRelation?
        console.log "deleting Relation between", userId, "and", otherUserId, "with weight", strength
        Relations.remove _id: existingRelation._id


walk = (userId) ->
  user = Meteor.users.findOne userId
  return if not user?
  return if not user.profile.hot_programs?
  query =
    user_ids: userId
  options =
    sort:
      weight: -1
    limit: 100
  counter = 0
  # update current Relations
  Relations.find(query, options).forEach (relation) ->
    otherUserId = if relation.user_ids[0] is userId then relation.user_ids[1] else relation.user_ids[0]
    otherUser = Meteor.users.findOne otherUserId
    strength = calculateWeight user, otherUser
    if strength?
      upsertRelation userId, otherUserId, strength

  # walk current Relations to nodes that are currently unconnected to userId
  Relations.find(query, options).forEach (relation) ->
    otherUserId = if relation.user_ids[0] is userId then relation.user_ids[1] else relation.user_ids[0]
    console.log "  walking node with userId: ", otherUserId
    innerQuery =
      $and: [
        user_ids: otherUserId
        user_ids: $ne: userId
      ]
      weight: $gt: 0.5 / relation.weight
    innerOptions =
      sort:
        weight: -1
      limit: 10

    Relations.find(innerQuery, innerOptions).forEach (secondRelation) ->
      thirdUserId = if secondRelation.user_ids[0] is otherUserId then secondRelation.user_ids[1] else secondRelation.user_ids[0]
      console.log "    visiting node with userId: ", thirdUserId
      thirdUser = Meteor.users.findOne thirdUserId
      strength = calculateWeight user, thirdUser
      if strength?
        upsertRelation userId, thirdUserId, strength
      counter++
      return if counter > 100

calculateWeight = (userA, userB) ->
  return null if (not userA.profile.history) or (not userB.profile.history) or (not userA.profile.hot_programs) or (not userB.profile.hot_programs)
  sumUserA = userA.profile.history.length
  sumUserB = userB.profile.history.length
  return compareTitleCounters userA.profile.hot_programs, sumUserA, userB.profile.hot_programs, sumUserB

harmonicMean = (a, b) ->
  return (2 * a * b) / (a + b)

compareTitleCounters = (a, suma, b, sumb) ->
  harmonic_max = harmonicMean suma, sumb
  likeness = 0
  for entryA in a
    for entryB in b
      if entryA.title == entryB.title
        likeness += harmonicMean entryA.counter, entryB.counter
  return likeness / harmonic_max
