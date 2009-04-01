# Needed to import datamapper and other gems
require 'rubygems'
require 'pathname'

# Add all external dependencies for the plugin here
gem 'dm-core',          '>=0.9.11'
gem 'dm-validations',   '>=0.9.11'
gem 'dm-is-remixable',  '>=0.9.11'

require 'dm-core'
require 'dm-validations'
require 'dm-is-remixable'

# Require plugin-files
require Pathname(__FILE__).dirname.expand_path / 'dm-is-cloneable' / 'is' / 'cloneable.rb'

# Include the plugin in Resource
DataMapper::Model.append_extensions DataMapper::Is::Cloneable
