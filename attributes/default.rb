default['certbot']['bin']['user'] = "root"
default['certbot']['bin']['group'] = "root"
default['certbot']['bin']['mode'] = 0755
default['certbot']['bin']['path'] = "/usr/local/bin/certbot-auto"
default['certbot']['bin']['download_uri'] = "https://dl.eff.org/certbot-auto"

default['certbot']['log'] = "/var/log/certbot-auto.log"

# if true, will use certbot's standalone server, otherwise will use webroot
default['certbot']['standalone'] = true

# path to the webroot directory (--webroot-path)
default['certbot']['webroot'] = ""

# list of domains to be registered
default['certbot']['domains'] = []

# pre and post hooks, e.g. "service apache2 stop"
default['certbot']['pre_hook'] = ""
default['certbot']['post_hook'] = ""

# full paths to the certificate files
# will create symbolic links in these paths pointing to the certificates in letsencrypt folders
default['certbot']['cert_path'] = ""
default['certbot']['chain_path'] = ""
default['certbot']['fullchain_path'] = ""
default['certbot']['key_path'] = ""

# two random hours of the day at any random minute within it
default['certbot']['schedule']["hour"] = [ Random.new.rand(0..11) ].map{ |n| [n, n+12] }.join(",")
default['certbot']['schedule']["minute"] = Random.new.rand(0..59).to_s
