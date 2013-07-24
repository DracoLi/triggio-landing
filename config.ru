require 'rubygems'
require 'bundler'
Bundle.require(:default)
require 'sass/plugin/rack'
require './myapp'

# Use sass for stylesheets
Sass::Plugin.options[:style] = :compressed
use Sass::Plugin::Rack

# Use coffeescript for javascript
use Rack::Coffee, root: 'public', urls: '/javascripts'

run MyApp
