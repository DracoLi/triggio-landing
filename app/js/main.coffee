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

  validateEmail: (email) ->
    re = /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/
    re.test(email)

  handleSignupError: (field, msg) ->
    console.log "handle #{field} Error: #{msg}"
    $(".signup-form .#{field}")
      .focus()
      .parents('.control-group')
      .addClass('error')

  configureSignupForm: ->
    $signup = $('.signup-form')
    $('.signup-form').submit =>

      # Do nothing when loading
      if $('.signup-form').hasClass 'loading'
        return false
      
      # Remove all errors
      $signup
        .find('.control-group')
        .removeClass('error')
        .find('.oh-no').html('')

      # Error checking
      hasError = false
      company = $signup.find('.company').val()
      email = $signup.find('.email').val()

      # validate email
      unless email? and AwesomeTools.validateEmail(email)
        AwesomeTools.handleSignupError 'email', 'Invalid emails'
        hasError = true

      # validate company name
      unless company? and company.length > 1
        AwesomeTools.handleSignupError 'company', 'Invalid company name'
        hasError = true

      return false if hasError

      # Submit waitlist if passed javascript validation
      $signup.addClass 'loading'
      $submit = $signup.find('input[type="submit"]').addClass 'loading'
      $.post('/signup', {company: company, email: email})
      .done (data) =>
        # Server side validation returned
        if data.success
          console.log 'success'
        else
          for field in data.error_fields
            @handleSignupError field, data.msg[field][0]
        console.log data
      .fail -> 
        console.log 'failed'
        $signup.find('.oh-no').html 'Oh no! Something went wrong...'
      .always -> 
        $signup.removeClass 'loading'
        $submit.removeClass 'loading'

      console.log 'company registered!'

      return false

  signedupDemo: ->
    console.log 'signedup demo'

    # Remove signin form
    
    # Play signedup events
    
    # Show success and share overlay
    
    @configureShare()
  
  configureShare: ->
    $('.share-links .fb').click (e) ->
      e.preventDefault()
      fbUrl = "https://www.facebook.com/sharer/sharer.php?u=#{encodeURIComponent(location.href)}"
      @openShareWindow fbUrl

    $('.share-links .tw').click (e) ->
      e.preventDefault()
      twitterMsg = "I just signed up for Triggio for my company! www.trigg.io"
      twUrl = "http://twitter.com/home?status=#{encodeURIComponent(twitterMsg)}"
      @openShareWindow fbshareUrl

  openShareWindow: (url) ->
    width = 626
    height = 436
    x = screen.width/2 - width/2
    y = screen.height/2 - height/2
    window.open url, 'Share', 
                "width=#{width},height=#{height},left=#{x},top=#{y}"

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

      AwesomeTools.configureSignupForm()
    , 4000
  , 2000
  

  
  
  