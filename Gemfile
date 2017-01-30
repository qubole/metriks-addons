##
 # Copyright (c) 2015. Qubole Inc
 # Licensed under the Apache License, Version 2.0 (the "License");
 # you may not use this file except in compliance with the License.
 # You may obtain a copy of the License at
 #
 #     http://www.apache.org/licenses/LICENSE-2.0
 #
 # Unless required by applicable law or agreed to in writing, software
 # distributed under the License is distributed on an "AS IS" BASIS,
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 # See the License for the specific language governing permissions and
 #    limitations under the License.
##

source 'https://rubygems.org'

gemspec

gem 'activesupport', '~> 4.2.7' if RUBY_VERSION < '2.2.0'
gem 'signalfx', '~> 0.1.0' if RUBY_VERSION < '2.2.0'

group :test do
  gem "rake"
  gem "rspec"
  gem "webmock"
end

gem "rest-client"
gem 'aws-sdk', '1.40.3'
