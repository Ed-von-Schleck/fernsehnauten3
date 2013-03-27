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
      "sub-title": 1
      start: 1
      stop: 1
  return Programs.find query, options

Meteor.publish "unknown_programs", ->
  query =
    _id: @userId
  options =
    fields:
      "profile.hot_programs": 1
  self = this
  self.old_unknown_programs = {}

  handle = Meteor.users.find(query, options).observeChanges
    added: (id, fields) =>
      console.log "added"
      if fields.profile? and fields.profile.hot_programs?
        known_program_titles = _.map fields.profile.hot_programs, (program) -> program.title
      else
        known_program_titles = []
      query =
        "title.0.0": $nin: known_program_titles
      options =
        fields:
          title: 1
          "sub-title": 1
          channel: 1
        limit: 100
      unknown_programs = Programs.find query, options
      unknown_programs.forEach (program) ->
        program.random = Math.random()
        self.added "unknown_programs", program._id, program
        self.old_unknown_programs[program._id] = program.title[0][0]

      self.old_known_program_titles = known_program_titles
      
    changed: (id, fields) =>
      console.log "changed"
      known_program_titles = _.map fields.profile.hot_programs, (program) -> program.title
      diff = _.difference known_program_titles, self.old_known_program_titles
      if diff.length isnt 0
        query =
          "title.0.0": $in: diff
        options =
          fields: _id: 1
        #Programs.find(query, options).forEach (program) ->
        #  self.removed "unknown_programs", program._id
        for _id, title of self.old_unknown_programs
          if title in diff
            self.removed "unknown_programs", _id
      self.old_known_program_titles = known_program_titles

  @ready()

  @onStop ->
    handle.stop()
