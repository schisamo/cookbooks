#
# Cookbook Name:: rabbitmq
# Recipe:: cluster
#
# Copyright 2009, Benjamin Black
# Copyright 2010, Opscode, Inc.
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
include_recipe "rabbitmq::default"

# find other rabbitmq nodes to cluster with
rabbitmq_servers = search(:node, %Q{recipes:"rabbitmq::cluster"}) || node
# we cluster by hostname to stop annoying Erlang "System NOT running to use fully qualified hostnames" errors
# you may need to update your /etc/hosts file with shortname => ip mappings
node[:rabbitmq][:cluster_disk_nodes] = rabbitmq_servers.map{|n| "#{n[:rabbitmq][:nodename]}@#{n[:hostname]}"}.sort

# write a shared erlang cookie
template "#{node[:rabbitmq][:state_dir]}/.erlang.cookie" do
  source "doterlang.cookie.erb"
  owner "rabbitmq"
  group "rabbitmq"
  mode 0400
end

# delete the mnesia directory to force a reset
directory node[:rabbitmq][:mnesia_dir] do
  action :nothing
  recursive true
  notifies :restart, resources(:service => "rabbitmq-server")
end

template "#{node[:rabbitmq][:conf_dir]}/rabbitmq_cluster.config" do
  source "rabbitmq_cluster.config.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :delete, resources(:directory => node[:rabbitmq][:mnesia_dir]), :immediately
end
