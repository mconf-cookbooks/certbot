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

cookbook_file node['certbot']['gen-fullchain-key']['path'] do
  mode "00755"
end

cmd = [ node['certbot']['bin']['path'], "certonly", "--non-interactive", "--register-unsafely-without-email", "--agree-tos", "--expand" ]
cmd << "--standalone" if node['certbot']['standalone']
cmd << "--webroot" if ! node['certbot']['standalone']
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

execute "generate fullchain key file" do
  command node['certbot']['gen-fullchain-key']['path']
  action :run
end

renew_cmd = [ "PATH=\"/sbin:/bin:$PATH\"", node['certbot']['bin']['path'], "renew" ]
renew_cmd << "--standalone" if node['certbot']['standalone']
renew_cmd << "--webroot" if ! node['certbot']['standalone']
renew_cmd << "--webroot-path #{node['certbot']['webroot']}" if node['certbot']['webroot'].to_s != ''
renew_cmd << "--pre-hook \"#{node['certbot']['pre_hook']}\"" if node['certbot']['pre_hook'].to_s != ''
renew_cmd << "--post-hook \"#{node['certbot']['post_hook']}\"" if node['certbot']['post_hook'].to_s != ''
renew_cmd << "--no-self-upgrade"
renew_cmd << "--non-interactive"
renew_cmd << "> #{node['certbot']['log']} 2>&1"
renew_cmd << "&& node['certbot']['gen-fullchain-key']['path']"
Chef::Log.info "Configuring cron to run: #{renew_cmd.join(" ")}"

cron "auto renew let's encrypt certificate" do
  hour node['certbot']['schedule']["hour"]
  minute node['certbot']['schedule']["minute"]
  command renew_cmd.join(" ")
end

links = {}
links["cert.pem"] = node['certbot']['cert_path'] if node['certbot']['cert_path'].to_s != ''
links["chain.pem"] = node['certbot']['chain_path'] if node['certbot']['chain_path'].to_s != ''
links["fullchain.pem"] = node['certbot']['fullchain_path'] if node['certbot']['fullchain_path'].to_s != ''
links["fullchain_key.pem"] = node['certbot']['fullchain_key_path'] if node['certbot']['fullchain_key_path'].to_s != ''
links["privkey.pem"] = node['certbot']['key_path'] if node['certbot']['key_path'].to_s != ''

ruby_block "create symlinks" do
  block do
    letsencrypt_certs = Dir.glob("/etc/letsencrypt/live/*").map{ |d| File.basename(d) }
    intersection = domains & letsencrypt_certs
    if ! intersection.empty?
      cert_dir = "/etc/letsencrypt/live/#{intersection.first}"
      links.each do |src, dst|
        FileUtils.mkdir_p File.dirname(dst)
        FileUtils.rm dst if File.symlink?(dst)
        FileUtils.ln_s "#{cert_dir}/#{src}", dst, force: true if ! intersection.empty?
      end
    end
  end
  action :run
end
