DEBUG = true

# setup our sound manager
soundManager.setup 
  preferFlash: false
  debugMode: DEBUG
  flashVersion: 9
  url: "/assets/swf/soundmanager2.swf"
  useHTML5Audio: true

window.AwesomeTools =

  opacityChange: 10

  # Adds events to our demo layer and animate them in fancily
  addInitialEvents: (events) ->
    # Add our initial events data
    $events = $('#demoLayer .events')
    $events.empty()
    for oneEvent in events
      $eventHTML = $(HandlebarsTemplates['event'](oneEvent))
      $eventHTML
        .addClass('future')
      $events.append $eventHTML

    # animate in our added events
    setTimeout =>
      @animateInEvents()
    , 500

  # Handles animating all newly added events in demoLayer
  animateInEvents: ->
    delay = 0
    delayInterval = 50
    opacity = 100

    # Loop through all events top animate them in with css3
    $('#demoLayer .event').each (index, eventNode) =>
      $oneEvent = $(eventNode)
      ((opacity, $oneEvent, delay) ->
        setTimeout ->
          $oneEvent
            .css('opacity', opacity / 100)
            .removeClass('future')
        , delay
      )(opacity, $oneEvent, delay)
      delay += delayInterval
      opacity = Math.max(opacity - @opacityChange, 0)

  sendEvent: (source, msg, soundName) ->
    console.log "(ADD) #{source}: #{msg} (#{soundName})"

    $('#demoLayer .events').attr 'class', 'events fan' # or wave

    # Animate in event
    $events = $('#demoLayer .events')
    oneEvent =  {source: source, msg: msg}
    $eventHTML = $(HandlebarsTemplates['event'](oneEvent))
    $events.prepend $eventHTML

    # Set up initial event positioning
    $eventHTML
      .addClass('past')
    $events.css('margin-top', '-56px')

    # Animate event with a short delay for initial css to take effect
    setTimeout =>
      $eventHTML
        .removeClass('past')
        .css('opacity', 1)
      $events.transition
        'delay': 200
        'margin-top': 0
      , 600
      @updateEvents()
    , 50

    # Play sound
    soundObj = soundManager.getSoundById(soundName)
    unless soundObj?
      soundObj = soundManager.createSound
                    id: soundName
                    url: "/assets/clips/#{soundName}.mp3"
    soundObj.play()

  updateEvents: ->
    opacity = 100
    $('#demoLayer .event').each (index, eventNode) =>
      $oneEvent = $(eventNode)
      $oneEvent.css('opacity', opacity / 100)
      opacity = Math.max(opacity - @opacityChange, 0)

$ ->
  # Enable placeholder cross browser
  $('input').placeholder()

  ### Start our demo ###

  # Send +1 visior event
  setTimeout ->
    AwesomeTools.sendEvent('Viewers', 
                           'Someone just visited Triggio :)', 
                           'new-visitor')
    setTimeout ->
      $('.demo-overlay').css 'opacity': 1
      $('#demoLayer').css 'polyfilter', 'blur(3px)'

      # Show waitlist form
      signupHTML = HandlebarsTemplates['signup']()
      config = 
        'items': {src: signupHTML}
        type: 'inline'
        modal: true
        mainClass: 'my-mfp-zoom-in sign-up'
        overflowY: 'scroll'
        removalDelay: 300
      $.magnificPopup.open config
    , 4000
  , 2000
  

  
  
  