$ ->
  window.set_disabled = ->
    activeQuestionnaires = $('.active-questionnaire')
    inactiveQuestionnaires = $('.inactive-questionnaire')
    if activeQuestionnaires.length > 0
      $.each inactiveQuestionnaires, (key, value) ->
        $(value).addClass('disabled')

  set_disabled()


