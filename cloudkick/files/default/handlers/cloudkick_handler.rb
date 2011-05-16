#
# Author:: Michael Leinartas (<@mleinart>)
# Author:: Greg Albrecht (<gba@gregalbrecht.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
#
# Copyright:: Copyright (c) 2011 Michael Leinartas
# Copyright:: Copyright (c) 2011 Greg Albrecht
# Copyright:: 2011, Opscode, Inc.
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
# See Also
#  http://wiki.opscode.com/display/chef/Exception+and+Report+Handlers
#  https://support.cloudkick.com/API/2.0
#  https://github.com/cloudkick/cloudkick-gem
#
# History
#  http://twitter.com/#!/ampledata/status/50718248886480896
#  http://twitter.com/#!/mleinart/status/50748954815635457
#  http://twitter.com/#!/ampledata/status/50991223296626688
#  http://twitter.com/#!/mleinart/status/51287128054841344
#  https://gist.github.com/886900
#  https://gist.github.com/890985
#
# Requirements
#  Cloudkick gem: $ sudo gem install cloudkick
#  JSON gem: $ sudo gem install json
#
# Usage
#  I. On the chef-client:
#    1. Add these four lines to your /etc/chef/client.rb, 
#       replacing "YOUR API KEY" and "YOUR API SECRET":
#         require '/var/chef/handler/cloudkick_handler'
#         ck_handler = CloudkickHandler.new('YOUR API KEY', 'YOUR API SECRET')
#         exception_handlers << ck_handler
#         report_handlers << ck_handler
#    2. Copy cloudkick_handler.rb into /var/chef/handler/
#  II. On http://www.cloudkick.com/:
#    1. Login and select 'Monitor' then 'New Monitor'.
#    2. Under 'Step 1: name it', 'Name' the monitor "chef-client status".
#    3. Under 'Step 2: add checks', for 'Type' select "HTTPS Push API".
#    4. Under 'Step 2: add checks', for 'Name' enter "chef-client run".
#    5. Click 'Add check'.
#

require 'rubygems'
Gem.clear_paths
require 'cloudkick'
require 'json'
require 'timeout'

class CloudkickHandler < Chef::Handler

  TIMEOUT = 10

  def initialize(oauth_key, oauth_secret, check_name = 'chef-client run')
    @oauth_key = oauth_key
    @oauth_secret = oauth_secret
    @check_name = check_name
  end

  def report
    Timeout::timeout(TIMEOUT) do
      if ck_client && ck_node && check_id
        Chef::Log.debug("Cloudkick node_id = #{ck_node.id}")
        Chef::Log.debug("Cloudkick check_id = #{check_id}")
        send_status
        send_metrics
      end
    end
  rescue
    Chef::Log.warn("Could not send data to Cloudkick: #{$!}")
  end

private
  def send_status
    status = {:node_id => ck_node.id.to_s}
    if run_status.success?
      status[:status] = 'ok'
      status[:details] = "Chef Run complete in #{run_status.elapsed_time.to_s} seconds. Updated resources: #{updated_resources}"
    else
      status[:status]= 'err'
      status[:details] = "Chef Run failed: #{run_status.formatted_exception}"
    end
    Chef::Log.debug("Sending status data to Cloudkick: #{status.inspect}")
    ck_client.access_token.post("/2.0/check/#{check_id}/update_status", status)
  end

  def send_metrics
    metrics = []
    metrics << { :metric_name => 'elapsed_time',
                 :value => run_status.elapsed_time.to_s,
                 :check_type => 'float' }
    metrics << { :metric_name => 'total_resource_count',
                 :value => run_status.all_resources.size.to_s,
                 :check_type => 'int' }
    metrics << { :metric_name => 'updated_resource_count',
                 :value => run_status.updated_resources.size.to_s,
                 :check_type => 'int' }
    metrics.each do |m|
      m[:node_id] = ck_node.id.to_s
      Chef::Log.debug("Sending metric data to Cloudkick: #{m.inspect}")
      ck_client.access_token.post("/2.0/data/check/#{check_id}", m)
    end
  end

  def ck_client
    @ckclient ||= Cloudkick::Base.new(@oauth_key, @oauth_secret)
  end

  def ck_node
    @cknode ||= ck_client.get("nodes", "node:#{node.name}").nodes.first
  end

  def check_id
    @check_id ||= begin
      resp, data = ck_client.access_token.get('/2.0/checks')
      if resp.code =~ /^2/
        JSON::parse(data)['items'].each do |item|
          if @check_name == item['details']['name']
            return item['id']
          end
        end
      else
        raise Exception, "received " + resp.code.to_s + " on list checks"
      end
      nil
    end
  end

  def updated_resources
    run_status.updated_resources.map{|r| r.to_s}.join(", ")
  end
end