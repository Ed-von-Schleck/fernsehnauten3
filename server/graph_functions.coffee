findUserRelations = (userId, limit=100) ->
  query =
    user_ids: userId
  options =
    sort:
      weight: -1
    limit: limit
  return Relations.find query, options


@getRecByFriendHistory = (userId) ->
  self = this
  query =
      start: $lt: +new Date / 1000 | 0
      stop: $gt: +new Date / 1000 | 0
    options =
      fields:
        title: 1
  currentProgramsMap = {}
  currentProgramTitles = []
  self.recommendations = {}
  currentPrograms = Programs.find(query, options).forEach (program) ->
    currentProgramsMap[program.title] = program._id
    currentProgramTitles.push program.title
    self.recommendations[program.title] = 0

  hot_programs = {}
  user = Meteor.users.findOne userId, {fields: "profile.hot_programs": 1}
  for program in user.profile.hot_programs
    hot_programs[program.title] = 1 #hash map lookups are faster than array lookups

  findUserRelations(userId).map (relation) ->
    otherUserId = if relation.user_ids[0] is userId then relation.user_ids[1] else relation.user_ids[0]
    innerQuery =
      _id: otherUserId
      "profile.hot_programs.title": $in: currentProgramTitles
    innerOptions =
      fields:
        "profile.hot_programs": 1

    otherUser = Meteor.users.findOne innerQuery, innerOptions
    if otherUser?
      for program in otherUser.profile.hot_programs
        if program.title of currentProgramsMap
          self.recommendations[program.title] += relation.weight * program.counter

  recommendation = null
  recommendationStrength = 0
  recommendationUnknown = null
  recommendationUnknownStrength = 0
  for title, strength of self.recommendations
    if strength > recommendationStrength
      recommendationStrength = strength
      recommendation = title
    if strength > recommendationUnknownStrength
      if not (title of hot_programs)
        recommendationUnknownStrength = strength
        recommendationUnknown = title
  result =
    recommendation: recommendation
    unknownRecommendation: recommendationUnknown
  return result



# The following function is completely untested as of yet
###
getRecommendations = (userId) ->
  query =
    user_ids: userId
  options =
    sort:
      weight: -1
    limit: 100
  recommendations = {}
  count = 0
  Relations.find(query, options).map (relation) ->
    otherUserId = if relation.user_ids[0] is userId then relation.user_ids[1] else relation.user_ids[0]
    otherUser = Meteor.users.findOne otherUserId
    if otherUser.profile.watching
      ++count
      if otherUser.profile.watching in recommendations
        recommendations[otherUser.profile.watching] += relation.weight
      else
        recommendations[otherUser.profile.watching] = relation.weight
  for program_id, strength of recommendations
    recommendations[program_id] = strength / count

  sorted_recommendation_pairs = _.sortBy _.pairs(recommendations), (pair) -> pair[1]
  return sorted_recommendation_pairs
###

@addRandomEdge = (userId) ->
  user = Meteor.users.findOne userId
  return if not user?
  return if not user.profile?
  return if not user.profile.hot_programs?
  query =
    _id: $ne: userId
  options =
    limit = 100
  Meteor.users.find(_id: $ne: userId).map (otherUser) ->
    console.log "  checking", otherUser._id
    if not Relations.findOne(user_ids: $all: [otherUser._id, userId])?
      strength = calculateWeight user, otherUser
      if strength?
        upsertRelation userId, otherUser._id, strength

@upsertRelation = (userId, otherUserId, strength) ->
    existingRelation = Relations.findOne
      user_ids:
        $all: [userId, otherUserId]

    if strength > 0.5
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


@walk = (userId) ->
  user = Meteor.users.findOne userId
  return if not user?.profile.hot_programs?
  counter = 0
  # update current Relations
  findUserRelations(userId).map (relation) ->
    otherUserId = if relation.user_ids[0] is userId then relation.user_ids[1] else relation.user_ids[0]
    otherUser = Meteor.users.findOne otherUserId
    strength = calculateWeight user, otherUser
    if strength?
      upsertRelation userId, otherUserId, strength

  # walk current Relations to nodes that are currently unconnected to userId
  findUserRelations(userId).map (relation) ->
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

    Relations.find(innerQuery, innerOptions).map (secondRelation) ->
      thirdUserId = if secondRelation.user_ids[0] is otherUserId then secondRelation.user_ids[1] else secondRelation.user_ids[0]
      console.log "    visiting node with userId: ", thirdUserId
      thirdUser = Meteor.users.findOne thirdUserId
      strength = calculateWeight user, thirdUser
      if strength?
        upsertRelation userId, thirdUserId, strength
      counter++
      return if counter > 100

calculateWeight = (userA, userB) ->
  return null if (not userA?.profile?.hot_programs?) or (not userB?.profile?.hot_programs?)
  sumUserA = userA.profile.watched_programs_count
  sumUserB = userB.profile.watched_programs_count
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
