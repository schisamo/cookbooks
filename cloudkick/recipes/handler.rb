#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Cookbook Name:: cloudkick
# Recipe:: handler
#
# Copyright 2011, Opscode, Inc.
#
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
# limitations under the License.
#

# force resource actions in compile phase so exception handler 
# fires for compile phase exceptions

gem_package "cloudkick" do
  action :nothing
end.run_action(:install)

remote_directory node['chef_handler']['handler_path'] do
  source 'handlers'
  mode "0755"
  recursive true
  action :nothing
end.run_action(:create)

chef_handler "CloudkickHandler" do
  source "#{node['chef_handler']['handler_path']}/cloudkick_handler.rb"
  arguments [node['cloudkick']['oauth_key'], node['cloudkick']['oauth_secret']]
  action :nothing
end.run_action(:enable)
