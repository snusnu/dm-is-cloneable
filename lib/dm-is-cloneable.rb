require 'pathname'

require 'dm-core'
require 'dm-validations'
require 'dm-is-remixable'

# Require plugin-files
require Pathname(__FILE__).dirname.expand_path / 'dm-is-cloneable' / 'is' / 'cloneable.rb'

# Include the plugin in Resource
DataMapper::Model.append_extensions DataMapper::Is::Cloneable
