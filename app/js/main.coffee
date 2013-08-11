DEBUG = true

# setup our sound manager
soundManager.setup 
  preferFlash: false
  debugMode: DEBUG
  flashVersion: 9
  url: "/assets/swf/soundmanager2.swf"
  useHTML5Audio: true

window.AwesomeTools =

  # Opacity decreasing rate for our events list
  opacityChange: 10

  targetCompany: null
  targetEmail: null

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
        @handleSignupError 'email', 'Invalid emails'
        hasError = true

      # validate company name
      unless company?.length > 1
        @handleSignupError 'company', 'Invalid company name'
        hasError = true

      return false if hasError

      # Submit waitlist if passed javascript validation
      $signup.addClass 'loading'
      $submit = $signup.find('input[type="submit"]').addClass 'loading'
      $.post('/signup', {company: company, email: email})
        .done (data) =>
          # Server side validation returned
          if data.success
            
            @targetCompany = company
            @targetEmail = email

            # Show our signedup demo after signup
            @signedupDemo data.queue
          else
            for field in data.error_fields
              @handleSignupError field, data.msg[field][0]
        .fail -> 
          console.log 'failed'
          $signup.find('.oh-no').html 'Oh no! Something went wrong...'
        .always -> 
          $signup.removeClass 'loading'
          $submit.removeClass 'loading'

      return false

  signedupDemo: (queue) ->
    console.log 'playing signedup demo'

    # Remove signin form
    $.magnificPopup.close()
    $('.demo-overlay').css 'opacity': 0
    $('#demoLayer').css 'polyfilter', 'blur(0px)'
    
    # Play signedup events
    setTimeout =>
      @sendEvent 'Waitlist', 
                 "#{@targetCompany} just joined our waitlist!",
                 'fantastic'
      setTimeout =>
        @sendEvent 'Draco', 
                   "OMG congrats team! #{@targetCompany} just signedup for Triggio!",
                   'killing-spree'
        setTimeout =>
          @showSharePopup(queue)
        , 6800
      , 4000
    , 1500
    
    # Show success and share overlay
    
    @configureShare()
  
  showSharePopup: (queue) ->
    # Show our overlay, hides demo
    $('.demo-overlay').css 'opacity': 1
    $('#demoLayer').css 'polyfilter', 'blur(3px)'

    # Show share popup
    shareHTML = HandlebarsTemplates['share'](queue)
    config = 
      'items': {src: shareHTML}
      type: 'inline'
      modal: true
      mainClass: 'my-mfp-zoom-in share-popup'
      overflowY: 'scroll'
      removalDelay: 300
    $.magnificPopup.open config

    @configureShare()

  configureShare: ->
    # Configure fb button
    $('.share-links .fb-share').click (e) =>
      @shareFBContent()

    # Configure twitter button and callback
    twttr.widgets.createShareButton 'http://trigg.io', 
      $('.share-links .tw-share')[0],
      null
      ,
        count: 'none'
        text: 'I just signed up my company for Triggio! Realtime musical notifications.'

    twttr.ready (twttr) =>
      twttr.events.bind 'tweet', (event) =>
        @websiteShared()

  websiteShared: ->
    # Update UI to reflect shared
    $('.share .waitlist').addClass 'hidden'
    $('.share .sharing-success').removeClass 'hidden'

    # Tell our database that this user has shared
    $.post '/shared', {email: @targetEmail}

  shareFBContent: ->
    FB.ui
      method: 'feed'
      name: 'Triggio | Realtime Musical Notifications'
      description: "Triggio, the realtime musical notifications for your company. Now open for limited beta signups."
      link: "http://www.trigg.io"
      picture: "http://www.trigg.io/triggio-fb.png"
    , (response) =>
      if response and response.post_id
        @websiteShared()

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
        mainClass: 'my-mfp-zoom-in signup-popup'
        overflowY: 'scroll'
        removalDelay: 300
      $.magnificPopup.open config

      AwesomeTools.configureSignupForm()
    , 4000
  , 2000
  

  
  
  