Template.improvement.helpers
  unknown_program: ->
    rand = Session.get "random"
    if not rand?
      rand = Math.random()
    unknown_program = UnknownPrograms.findOne random: $gt: rand
    if not unknown_program?
      unknown_program = UnknownPrograms.findOne random: $lt: rand
    return unknown_program


  
