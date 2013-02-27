Template.improvement.events
  "click .feedback_button": (event) ->
    $target = $(event.currentTarget)
    switch $target.attr "data-value"
      when "yes"
        #console.log $target.attr "data-program_title"
        Meteor.call "like", $target.attr "data-program_title"
        Session.set "random", Math.random()
      when "no"
        Session.set "random", Math.random()
      else console.error "no useful value for improvement button"
