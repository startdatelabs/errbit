require 'capistrano/setup'
require 'capistrano/deploy'

require 'capistrano/rvm'
require 'capistrano/bundler'
require 'capistrano/rails'
require 'capistrano/rails/assets'
require 'capistrano3/unicorn'
require 'airbrussh/capistrano'

Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
