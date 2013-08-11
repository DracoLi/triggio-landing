require 'sinatra'
require 'sinatra/support'
require 'json'
require 'pony'

# Database
require 'sinatra/activerecord'
require './environments'

# Use sass, coffeescript, and handlebars like a pro coder
require 'sass'
require 'compass'
require 'coffee-script'
require 'sinatra/handlebars'

# Asset Management
require 'sinatra/base'
require 'sinatra/assetpack'
require "sinatra/reloader"

# Models
require 'validates_email_format_of'
require './models/wait_lists.rb'

# Set default time zone
timezone = 'Eastern Time (US & Canada)'
ActiveRecord::Base.default_timezone = timezone
Time.zone = timezone

class MyApp < Sinatra::Base
  # Set app root
  base = File.dirname(__FILE__)
  set :root, base

  configure :development do
    register Sinatra::Reloader
  end
  register Sinatra::ActiveRecordExtension
  register Sinatra::AssetPack
  register Sinatra::CompassSupport
  register Sinatra::Handlebars

  # Compass support
  set :sass, Compass.sass_engine_options
  set :sass, { :load_paths => sass[:load_paths] + [ "#{base}/app/css" ] }
  set :scss, sass

  handlebars {
    templates '/js/templates.js', ['app/templates/*']
  }

  assets {
    serve '/js',     from: 'app/js'        # Default
    serve '/css',    from: 'app/css'       # Default
    serve '/images', from: 'app/images'    # Default
    serve '/vendor', from: 'app/vendor'

    # The second parameter defines where the compressed version will be served.
    # (Note: that parameter is optional, AssetPack will figure it out.)
    # The final parameter is an array of glob patterns defining the contents
    # of the package (as matched on the public URIs, not the filesystem)
    js :app, '/js/app.js', [
      '/vendor/jquery-placeholder/jquery.placeholder.min.js',
      '/vendor/magnific-popup/dist/jquery.magnific-popup.min.js',
      '/vendor/CSS-Filters-Polyfill/lib/cssParser.js',
      '/vendor/CSS-Filters-Polyfill/lib/css-filters-polyfill.js',
      '/vendor/jquery.transit/jquery.transit.js',
      '/vendor/soundmanager/script/soundmanager2.js',
      '/vendor/stroll/js/stroll.min.js',
      '/js/templates.js',
      '/js/main.js'
    ]

    css :application, '/css/application.css', [
      '/vendor/bootstrap-glyphicons/bootstrap.css',
      '/vendor/bootstrap-glyphicons/bootstrap-glyphicons.css',
      '/vendor/magnific-popup/dist/magnific-popup.css',
      '/vendor/stroll/css/stroll.min.css',
      '/vendor/hint.css/hint.css',
      '/css/fonts.css',
      '/css/main.css'
    ]

    js_compression  :jsmin    # :jsmin | :yui | :closure | :uglify
    css_compression :simple   # :simple | :sass | :yui | :sqwish
  }

  get '/' do
    @lineup_count = WaitList.count
    @initial_events = JSON.dump YAML.load(File.read('app/assets/events.yml'))
    erb :index
  end

  post '/signup' do
    # Get company name and email
    @company = params[:company]
    @email = params[:email]

    # Save data
    a = WaitList.create(company: @company, email: @email)
    unless a.valid?
      error_fields = a.errors.messages.keys
      error_msg = a.errors.messages
    else
      # Get waitlist position
      currentPos = (WaitList.count * 3 + 20)
      newPos = currentPos * 0.6
      @queue = { :current => currentPos, :new => newPos.to_i }

      # Send signup email
      Pony.mail({
        to: @email,
        from: "Draco Li <draco@trigg.io>",
        subject: "Thanks for being awesome and signing up for Triggio!",
        # html_body: erb(:email, layout: false),
        body: erb(:email, layout: false),
        via: :smtp,
        via_options: {
          address: "smtp.mandrillapp.com",
          port: '587',
          enable_starttls_auto: true,
          user_name: "draco@dracoli.com",
          password: "NdosrPoWlLga9ATRDikxYA",
          authentication: :plain,
          domain: "localhost"
        }
      })
    end
    
    content_type :json
    {success: a.valid?, 
      :error_fields => error_fields, 
      :msg => error_msg,
      :queue => @queue}.to_json
  end

  post '/shared' do
    email = params[:email]

    # Save this share in database
    waitlist = WaitList.where(email: email).last
    waitlist.shared = true
    waitlist.save
  end

  run! if app_file == $0
end

class Sinatra::AssetPack::Package
  def to_production_html(path_prefix, options={})
    to_development_html(path_prefix, options)
  end
end