#
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Nuo Yan (<nuo@opscode.com>)
# Author:: Joshua Timberman (<joshua@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Cookbook Name:: gecode
# Recipe:: default
#
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

case node['platform']
when 'ubuntu','debian'

  include_recipe 'apt'

  # use opscode apt repo for older releases
  if ubuntu_before_natty? || debian_before_wheezy?

    # add Opscode's apt repo to sources
    apt_repository "opscode" do
      uri "http://apt.opscode.com"
      components ["main"]
      distribution node['lsb']['codename']
      key "2940ABA983EF826A"
      keyserver "pgpkeys.mit.edu"
      action :add
      notifies :run, resources(:execute => "apt-get update"), :immediately
    end

  end

  apt_package 'libgecode-dev' do
    action :install
  end

when 'redhat','centos'

  include_recipe 'build-essential'

  bash "build gecode from source" do
    cwd "/tmp"
    code <<-EOH
    curl -C - -O  http://www.gecode.org/download/gecode-3.5.0.tar.gz
    tar zxvf gecode-3.5.0.tar.gz
    cd gecode-3.5.0 && ./configure
    make && make install
    EOH
  end

else
  raise "This recipe does not yet support installing Gecode 3.5.0+ for your platform"
end
