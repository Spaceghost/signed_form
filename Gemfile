source 'https://rubygems.org'

# Specify your gem's dependencies in signed_form.gemspec
gemspec

rails_version = ENV['RAILS_VERSION'] || 'master'

case rails_version
when /master/
  gem 'rails', github: 'rails/rails'
  gem 'arel', github: 'rails/arel'
when /^3-2/
  gem 'rails', github: 'rails/rails', branch: rails_version
  gem 'strong_parameters'
when /-stable$/
  gem 'rails', github: 'rails/rails', branch: rails_version
else
  gem 'rails', rails_version
end
