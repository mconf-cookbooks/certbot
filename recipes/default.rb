#
# Cookbook Name:: certbot
# Recipe:: default
#
# Copyright 2016, Mconf Tecnologia
#
# All rights reserved - Do Not Redistribute
#

remote_file node['certbot']['bin']['path'] do
  owner  node['certbot']['bin']['user']
  group  node['certbot']['bin']['group']
  mode   node['certbot']['bin']['mode']
  source node['certbot']['bin']['download_uri']
end

cmd = [ node['certbot']['bin']['path'], "certonly", "--non-interactive", "--register-unsafely-without-email", "--agree-tos" ]
cmd << "--standalone" if node['certbot']['standalone']
cmd << "--webroot-path #{node['certbot']['webroot']}" if node['certbot']['webroot'].to_s != ''
cmd << "--post-hook \"#{node['certbot']['post_hook']}\"" if node['certbot']['post_hook'].to_s != ''
cmd << "--cert-path #{node['certbot']['cert_path']}" if node['certbot']['cert_path'].to_s != ''
cmd << "--chain-path #{node['certbot']['chain_path']}" if node['certbot']['chain_path'].to_s != ''
cmd << "--fullchain-path #{node['certbot']['fullchain_path']}" if node['certbot']['fullchain_path'].to_s != ''
cmd << "--key-path #{node['certbot']['key_path']}" if node['certbot']['key_path'].to_s != ''
cmd << "--domains #{([] + node['certbot']['domains']).join(" ")}" if ! node['certbot']['domains'].empty?
Chef::Log.info "Executing: #{cmd.join(" ")}"

execute "install certbot" do
  command cmd.join(" ")
  action :run
end

renew_cmd = [ node['certbot']['bin']['path'], "renew" ]
renew_cmd << "--standalone" if node['certbot']['standalone']
renew_cmd << "--webroot #{node['certbot']['webroot']}" if node['certbot']['webroot'].to_s != ''
renew_cmd << "--post-hook \"#{node['certbot']['post_hook']}\"" if node['certbot']['post_hook'].to_s != ''
renew_cmd << "--no-self-upgrade"
renew_cmd << "--quiet"

cron "auto renew" do
  hour [ Random.new.rand(0..11) ].map{ |n| [n, n+12] }.join(",")
  minute Random.new.rand(0..59).to_s
  command renew_cmd.join(" ")
end
