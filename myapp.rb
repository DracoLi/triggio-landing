require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/base'
require 'sinatra/assetpack'
require "sinatra/reloader"
require './environments'

class MyApp < Sinatra::Base
  # configure :development do
  register Sinatra::Reloader
  # end
  
  set :root, File.dirname(__FILE__) # You must set app root

  register Sinatra::AssetPack

  assets {
    serve '/js',     from: 'app/js'        # Default
    serve '/css',    from: 'app/css'       # Default
    serve '/images', from: 'app/images'    # Default

    # The second parameter defines where the compressed version will be served.
    # (Note: that parameter is optional, AssetPack will figure it out.)
    # The final parameter is an array of glob patterns defining the contents
    # of the package (as matched on the public URIs, not the filesystem)
    js :app, '/js/app.js', [
      '/js/main.js'
    ]

    css :application, '/css/application.css', [
      '/vendor/normalize-css/normalize.css',
      '/css/main.css'
    ]

    js_compression  :jsmin    # :jsmin | :yui | :closure | :uglify
    css_compression :simple   # :simple | :sass | :yui | :sqwish
  }

  get '/' do
    erb :index
  end

  run! if app_file == $0
end

class WaitList < ActiveRecord::Base

end


# get '/js/:script.js' do |script|
#   coffee :"coffee/#{script}"
# end

# get '/css/:stylesheet.css' do |stylesheet|
#   scss :"scss/#{stylesheet}"
# end