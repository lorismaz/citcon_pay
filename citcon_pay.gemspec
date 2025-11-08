# frozen_string_literal: true

require_relative 'lib/citcon_pay/version'

Gem::Specification.new do |spec|
  spec.name = 'citcon_pay'
  spec.version = CitconPay::VERSION
  spec.authors = ['Your Name']
  spec.email = ['your.email@example.com']

  spec.summary = 'Ruby client for CitconPay API'
  spec.description = 'A Ruby client library for the CitconPay payment API, supporting Alipay, WeChat Pay, UnionPay, PayPal, and more'
  spec.homepage = 'https://github.com/yourusername/citcon_pay'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/yourusername/citcon_pay'
  spec.metadata['changelog_uri'] = 'https://github.com/yourusername/citcon_pay/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[
                          lib/**/*.rb
                          README.md
                          LICENSE.txt
                          CHANGELOG.md
                        ])

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'faraday', '~> 2.0'
  spec.add_dependency 'faraday-multipart', '~> 1.0'

  # Development dependencies
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'vcr', '~> 6.1'
  spec.add_development_dependency 'webmock', '~> 3.18'
end
