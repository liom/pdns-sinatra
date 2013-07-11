## Copyright (C) 2013 The rSmart Group, Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>

require 'rubygems'
require 'domain_controller'

config_file = '/etc/pdns/pdns-rest.yaml'

begin
  config = YAML.load_file(config_file)
rescue YAML::Error
  abort "failed to read configuration file #{config_file}"
end

env = 'production'
env_conf = config[env]
if env_conf.nil? then
  abort "configuration not found for environment: #{env}"
end

db_user     = env_conf["db_user"]
db_pass     = env_conf["db_pass"]
db_host     = env_conf["db_host"]
db_name     = env_conf["db_name"]
port        = env_conf["port"]
log_dir     = env_conf["log_dir"]
loglevel    = env_conf["loglevel"]
ssl_enabled = env_conf["ssl_enabled"]

if !File.exists?(log_dir) then
  begin
    Dir.mkdir(log_dir, 0750)
  rescue Exception => e
    $stderr.puts "cannot create log directory: #{log_dir}"
  end
end

Domain_controller = Rack::Builder.new do
  use Rack::Reloader, 0
  use Rack::ContentLength
  map '/' do
    run DomainController.new(db_user, db_pass, db_host, db_name, env, log_dir, loglevel)
  end
end.to_app

run Domain_controller