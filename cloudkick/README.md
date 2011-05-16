Description
===========

Installs and configures the Cloudkick Agent, and integrates it with Chef.  Also contains a Chef Handler for sending data to Cloudkick in response to a Chef run succeeding or failing.

Requirements
============

Platform
--------

* Debian, Ubuntu
* CentOS, Red Hat, Fedora

Cookbooks
---------

* apt (leverages apt_repository LWRP)
* yum (leverages yum_repository LWRP)
* chef_handler (leverages chef_handler LWRP)

The `apt_repository` and `yum_repository` LWRPs are used from these cookbooks to create the proper repository entries so the cloudkick agent can be downloaded and installed.

Chef Handlers
=============

CloudkickHandler
----------------

Can behave as a [Chef report or exception handler](http://wiki.opscode.com/display/chef/Exception+and+Report+Handlers). Successful Chef runs will report a list of updated resources to Cloudkick.  Unsuccessful Chef runs will report the exception that caused failure to Cloudkick.

The following metrics are reported to Cloudkick:

* elapsed_time
* total resource count of current node
* updated resource count of current node

In order to leverage the Cloudkick handler a monitor and check will need to be created in your Cloudkick account:

1. Login and select 'Monitor' then 'New Monitor'.
2. Under 'Step 1: name it', 'Name' the monitor "chef-client status".
3. Under 'Step 2: add checks', for 'Type' select "HTTPS Push API".
4. Under 'Step 2: add checks', for 'Name' enter "chef-client run".
5. Click 'Add check'.

Be sure the API key also has `write` access permissions.

### Initialization Arguments

- 0: the API key (oauth_key)
- 1: the API key's secret (oauth_secret) 
- 2: the name of the check data is pushed to. default is `chef-client run`

Recipe Usage
============

default
-------

In order for the agent to function, you'll need to have defined your Cloudkick API key and secret.  We recommend you do this in a Role, which should also take care of applying the `cloudkick::default` recipe.

Assuming you name the role 'cloudkick', here is the required json:

    {
      "name": "cloudkick",
      "chef_type": "role",
      "json_class": "Chef::Role",
      "default_attributes": {

      },
      "description": "Configures Cloudkick",
      "run_list": [
        "recipe[cloudkick]"
      ],
      "override_attributes": {
        "cloudkick": {
          "oauth_key": "YOUR KEY HERE"
          "oauth_secret": "YOUR SECRET HERE"
        }
      }
    }

If you want Cloudkick installed everywhere, we recommend you just add the cloudkick attributes to a base role.

All of the data about the node from Cloudkick is available in node['cloudkick'] - for example: 

    "cloudkick": {
      "oauth_key": "YOUR KEY HERE",
      "oauth_secret": "YOUR SECRET HERE",
      "data": {
        "name": "slice204393",
        "status": "running",
        "ipaddress": "173.203.83.199",
        "provider_id": "padc2665",
        "tags": [
          "agent",
          "cloudkick"
        ],
        "agent_state": "connected",
        "id": "n87cfc79c5",
        "provider_name": "Rackspace",
        "color": "#fffffff"
      }
    }

Of particular interest is the inclusion of the Cloudkick tags.  This will allow you to search Chef via tags placed on nodes within Cloudkick:

    $ knife search node 'cloudkick_data_tags:agent' -a fqdn
    {
      "rows": [
        {
          "fqdn": "slice204393",
          "id": "slice204393"
        }
      ],
      "start": 0,
      "total": 1
    }
  
We automatically add a tag for each Role applied to your node.  For example, if your node had a run list of:

    "run_list": [ "role[webserver]", "role[database_master]" ]

The node will automatically have the 'webserver' and 'database_master' tags within Cloudkick.

handler
-------

Leverages the `chef_handler` LWRP to automatically register the `CloudkickHandler` as a [Chef report and exception handler](http://wiki.opscode.com/display/chef/Exception+and+Report+Handlers).  See the complete description of `CloudkickHandler` above.

License and Author
==================

Author:: Adam Jacob (<adam@opscode.com>)
Author:: Seth Chisamore (<schisamo@opscode.com>)
Copyright:: 2010-2011, Opscode, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
