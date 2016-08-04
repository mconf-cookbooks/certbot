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

cmd = [ node['certbot']['bin']['path'], "certonly", "--non-interactive", "--register-unsafely-without-email", "--agree-tos", "--expand" ]
cmd << "--standalone" if node['certbot']['standalone']
cmd << "--webroot-path #{node['certbot']['webroot']}" if node['certbot']['webroot'].to_s != ''
cmd << "--pre-hook \"#{node['certbot']['pre_hook']}\"" if node['certbot']['pre_hook'].to_s != ''
cmd << "--post-hook \"#{node['certbot']['post_hook']}\"" if node['certbot']['post_hook'].to_s != ''
domains = [] + node['certbot']['domains']
domains.each do |domain|
  cmd << "--domain #{domain}"
end
Chef::Log.info "Executing: #{cmd.join(" ")}"

execute "install certbot" do
  command cmd.join(" ")
  action :run
end

renew_cmd = [ node['certbot']['bin']['path'], "renew" ]
renew_cmd << "--standalone" if node['certbot']['standalone']
renew_cmd << "--webroot #{node['certbot']['webroot']}" if node['certbot']['webroot'].to_s != ''
renew_cmd << "--pre-hook \"#{node['certbot']['pre_hook']}\"" if node['certbot']['pre_hook'].to_s != ''
renew_cmd << "--post-hook \"#{node['certbot']['post_hook']}\"" if node['certbot']['post_hook'].to_s != ''
renew_cmd << "--no-self-upgrade"
renew_cmd << "--quiet"

cron "auto renew let's encrypt certificate" do
  hour node['certbot']['schedule']["hour"]
  minute node['certbot']['schedule']["minute"]
  command renew_cmd.join(" ")
end

links = {}
links["cert.pem"] = node['certbot']['cert_path'] if node['certbot']['cert_path'].to_s != ''
links["chain.pem"] = node['certbot']['chain_path'] if node['certbot']['chain_path'].to_s != ''
links["fullchain.pem"] = node['certbot']['fullchain_path'] if node['certbot']['fullchain_path'].to_s != ''
links["privkey.pem"] = node['certbot']['key_path'] if node['certbot']['key_path'].to_s != ''

ruby_block "create symlinks" do
  block do
    links.each do |src, dst|
      FileUtils.mkdir_p File.dirname(dst)
      letsencrypt_certs = Dir.glob("/etc/letsencrypt/live/*").map{ |d| File.basename(d) }
      intersection = domains & letsencrypt_certs
      if !intersection.empty?
        FileUtils.rm_f dst
        FileUtils.ln_s "/etc/letsencrypt/live/#{intersection.first}/#{src}", dst
      end
    end
  end
  action :run
end
