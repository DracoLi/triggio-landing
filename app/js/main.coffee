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

  # Saves our waitlist data for recording link sharing
  targetCompany: null
  targetEmail: null
  waitlist: null

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
    delay = 0           # Delay for each event
    delayInterval = 50  # Delay between events animation
    opacity = 100       # Starting event opacity

    # Loop through all events top animate them in with css3
    $('#demoLayer .event').each (index, eventNode) =>
      $oneEvent = $(eventNode)

      # Encapsulates current loop values
      do (opacity, $oneEvent, delay) ->
        setTimeout ->
          $oneEvent
            .css('opacity', opacity / 100)
            .removeClass('future')
        , delay

      # Prepare values for the next event
      delay += delayInterval
      opacity = Math.max(opacity - @opacityChange, 0)


  # Send an event to our demo
  sendEvent: (source, msg, soundName) ->
    console.log "(ADD) #{source}: #{msg} (#{soundName})" if DEBUG

    # Make sure when adding new events, they are animated differently
    $('#demoLayer .events').attr 'class', 'events fan' # or wave

    # Add new event to DOM
    $events = $('#demoLayer .events')
    oneEvent =  {source: source, msg: msg}
    $eventHTML = $(HandlebarsTemplates['event'](oneEvent))
    $events.prepend $eventHTML

    # Set up initial event positioning
    $eventHTML
      .addClass('past')
    $events.css('margin-top', '-56px')

    # Animate event with a short delay for adjusted css to take effect
    setTimeout =>
      # Animates in new event
      $eventHTML
        .removeClass('past')
        .css('opacity', 1)

      # Animates the positioning of all events
      $events.transition
        'delay': 200
        'margin-top': 0
      , 600

      # This updates rest of the events to reflect the new event
      # Currently this updates the opacity
      @updateEvents()
    , 50

    # Play event sound
    soundObj = soundManager.getSoundById(soundName)
    unless soundObj?
      # Create sound on demand
      soundObj = soundManager.createSound
                    id: soundName
                    url: "/assets/clips/#{soundName}.mp3"
    soundObj.play()


  # Updates demo events' opacity
  updateEvents: ->
    opacity = 100
    $('#demoLayer .event').each (index, eventNode) =>
      $oneEvent = $(eventNode)
      $oneEvent.css 'opacity', opacity / 100
      opacity = Math.max(opacity - @opacityChange, 0)


  # Simple front-end email validation regex
  validateEmail: (email) ->
    re = /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/
    re.test(email)


  # Display error for signup form
  handleSignupError: (field, msg) ->
    console.log "handle #{field} Error: #{msg}" if DEBUG
    $(".signup-form .#{field}")
      .focus()
      .parents('.control-group')
      .addClass('error')
      .find('.error-msg')
      .html(msg)


  clearSignupErrors: ->
    $signup = $('.signup-form')
    $signup
      .find('.control-group')
      .removeClass('error')
      .find('.error-msg').html('')
    $signup.find('.oh-no').html('')


  configureSignupForm: ->
    $signup = $('.signup-form')
    $signup.submit =>
      # Do nothing when loading
      return false if $('.signup-form').hasClass 'loading'
        
      @clearSignupErrors()      

      # Error checking
      hasError = false
      company = $signup.find('.company').val()
      email = $signup.find('.email').val()

      # validate email
      unless email? and AwesomeTools.validateEmail(email)
        @handleSignupError 'email', 'invalid email'
        hasError = true

      # validate company name
      unless company?.length > 1
        @handleSignupError 'company', 'invalid company name'
        hasError = true

      return false if hasError

      # Show form loading
      $signup.addClass 'loading'
      $submit = $signup.find('input[type="submit"]').addClass 'loading'
      oriSubValue = $submit.val()
      $submit.val 'Trigging...'

      # Post request to signup
      $.post('/signup', {company: company, email: email})
        .done (data) =>
          # Server side validation returned
          if data.success
            @targetCompany = company
            @targetEmail = email
            @waitlist = data.queue

            # Show our signedup demo after signup
            @signedupDemo()
          else
            for field in data.error_fields
              @handleSignupError field, data.msg[field][0]
        .fail -> 
          console.log 'failed' if DEBUG
          $submit.val oriSubValue
          $signup.find('.oh-no').html 'Oh no! Something went wrong...'
        .always -> 
          $signup.removeClass 'loading'
          $submit.removeClass 'loading'

      false


  # Play a cool Triggio demo after someone signs up
  signedupDemo: ->
    # Remove signin form
    $.magnificPopup.close()
    $('.demo-overlay').css 'opacity': 0
    $('#demoLayer').css 'polyfilter', 'blur(0px)'
    
    # Play signedup events
    firstEventDuration = 4000
    secondEventDuration = 6400
    demoDelay = 1500
    setTimeout =>
      @sendEvent 'Waitlist', 
                 "#{@targetCompany} just joined our waitlist!",
                 'fantastic'
      setTimeout =>
        @sendEvent 'Draco', 
                   "OMG congrats team! #{@targetCompany} just signedup for Triggio!",
                   'killing-spree'
        setTimeout =>
          @showSharePopup()
        , secondEventDuration
      , firstEventDuration
    , demoDelay
  

  showSharePopup: ->
    # Show our overlay, hides demo
    $('.demo-overlay').css 'opacity': 1
    $('#demoLayer').css 'polyfilter', 'blur(3px)'

    # Show share popup
    shareHTML = HandlebarsTemplates['share'](@waitlist)
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
      $('.share-links .tw-share')[0], null, 
        count: 'none'
        text: 'I signed up my company for Triggio. Realtime musical notifications, '
    twttr.ready (twttr) =>
      twttr.events.bind 'tweet', (event) =>
        @websiteShared()


  shareFBContent: ->
    FB.ui
      method: 'feed'
      name: 'Triggio | Realtime Musical Notifications'
      description: "Triggio, realtime musical notifications for your company. Now open for limited beta signups."
      link: "http://www.trigg.io"
      picture: "http://www.trigg.io/triggio-fb.png"
    , (response) =>
      if response and response.post_id
        @websiteShared()


  websiteShared: ->
    # Update UI to reflect shared
    $('.share .waitlist').addClass 'hidden'
    $('.share .sharing-success').removeClass 'hidden'

    # Tell our database that this user has shared
    $.post '/shared', {email: @targetEmail}


$ ->
  # Enable placeholder cross browser
  $('input').placeholder()

  ### Start our demo ###

  # Send +1 visior event
  newVisitorDemoDuration = 4 * 1000
  setTimeout ->
    AwesomeTools.sendEvent('Viewers', 
                           'Someone just visited Triggio :)', 
                           'new-visitor')
    setTimeout ->
      # Animate in our overlay
      $('.demo-overlay').css 'opacity': 1
      $('#demoLayer').css 'polyfilter', 'blur(3px)'

      # Animate in our learn more link since its not part of waitlist popup
      $('.learn-more').removeClass('hidden')

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
    , newVisitorDemoDuration
  , 2000