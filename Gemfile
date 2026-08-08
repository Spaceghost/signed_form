source 'https://rubygems.org'

# Specify your gem's dependencies in signed_form.gemspec
gemspec

rails_version = ENV.fetch('RAILS_VERSION', '8.1.3')

case rails_version
when 'main', 'master'
  gem 'rails', github: 'rails/rails'
when /-stable$/
  gem 'rails', github: 'rails/rails', branch: rails_version
else
  gem 'rails', rails_version
end
