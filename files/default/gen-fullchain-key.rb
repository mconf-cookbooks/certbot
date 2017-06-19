#!/usr/bin/ruby

Dir.glob("/etc/letsencrypt/live/**/fullchain.pem").each do |fullchain|
    dir = File.dirname(fullchain)
    privkey = "#{dir}/privkey.pem"
    fullchain_key = "#{dir}/fullchain_key.pem"
    `cat #{fullchain} #{privkey} > #{fullchain_key}`
end
