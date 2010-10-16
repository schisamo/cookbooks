# Where the various parts of rabbitmq are
case platform
when "redhat","centos","fedora","suse"
  default[:rabbitmq][:log_dir] = "/var/log/rabbitmq"
  default[:rabbitmq][:conf_dir] = "/etc/rabbitmq"
  default[:rabbitmq][:state_dir] = "/var/lib/rabbitmq"
  default[:rabbitmq][:mnesia_dir] = "#{rabbitmq[:state_dir]}/mnesia"
when "debian","ubuntu"
  default[:rabbitmq][:log_dir] = "/var/log/rabbitmq"
  default[:rabbitmq][:conf_dir] = "/etc/rabbitmq"
  default[:rabbitmq][:state_dir] = "/var/lib/rabbitmq"
  default[:rabbitmq][:mnesia_dir] = "#{rabbitmq[:state_dir]}/mnesia"
else
  default[:rabbitmq][:log_dir] = "/var/log/rabbitmq"
  default[:rabbitmq][:conf_dir] = "/etc/rabbitmq"
  default[:rabbitmq][:state_dir] = "/var/lib/rabbitmq"
  default[:rabbitmq][:mnesia_dir] = "#{rabbitmq[:state_dir]}/mnesia"
end

default[:rabbitmq][:nodename]  = "rabbit"
default[:rabbitmq][:address]  = "0.0.0.0"
default[:rabbitmq][:port]  = "5672"
default[:rabbitmq][:erl_args]  = "+K true +A 30 \
-kernel inet_default_listen_options [{nodelay,true},{sndbuf,16384},{recbuf,4096}] \
-kernel inet_default_connect_options [{nodelay,true}]"
default[:rabbitmq][:start_args] = ""
default[:rabbitmq][:cluster] = "no"
default[:rabbitmq][:cluster_config] = "#{rabbitmq[:conf_dir]}/rabbitmq_cluster.config"
default[:rabbitmq][:cluster_disk_nodes] = []

::Chef::Node.send(:include, Opscode::OpenSSL::Password)
set_unless[:rabbitmq][:erlang_cookie] = secure_password
#SERVER_ERL_ARGS="${SERVER_ERL_ARGS} -setcookie mycookie"