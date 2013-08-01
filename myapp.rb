require 'sinatra'
require 'sinatra/support'

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

  run! if app_file == $0
end


# get '/js/:script.js' do |script|
#   coffee :"coffee/#{script}"
# end

# get '/css/:stylesheet.css' do |stylesheet|
#   scss :"scss/#{stylesheet}"
# end