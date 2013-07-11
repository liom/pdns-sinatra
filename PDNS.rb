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

module PDNS
  require 'logger'
  require 'PDNS/domain'
  require 'PDNS/record'
  require 'PDNS/supermaster'

  def self.config_log (log_dir, loglevel)
    use_stdout = false

    pdns_log = "#{log_dir}/pdns.log"
    if log_dir.nil? or log_dir.empty? then
      @@log = Logger.new($stdout)
      @@log.info 'using stdout for logging'
      use_stdout = true
    else
      created = false
      begin
        FileUtils.touch(pdns_log)
        created = true
      rescue Exception => e
        $stderr.puts "cannot write to log #{pdns_log}: #{e.message}"
      end

      if created then
        @@log = Logger.new(pdns_log, 'daily')
      else
        @@log = Logger.new($stdout)
        @@log.error "#{pdns_log} is not writable, logging to stdout"
        use_stdout = true
      end
    end

    case loglevel
    when 'DEBUG'
      @@log.level = Logger::DEBUG
      dm_level = :debug
    when 'INFO'
      @@log.level = Logger::INFO
      dm_level = :info
    when 'WARN'
      @@log.level = Logger::WARN
      dm_level = :warn
    when 'ERROR'
      @@log.level = Logger::ERROR
      dm_level = :error
    when 'FATAL'
      @@log.level = Logger::FATAL
      dm_level = :fatal
    else
      @@log.level = Logger::WARN
      dm_level = :warn
    end

    if use_stdout then
      DataMapper::Logger.new($stdout, dm_level)
    else
      DataMapper::Logger.new(pdns_log, dm_level)
    end

  end

  def self.set_or_dft (val, dft = '')
    if val.nil? or val.empty? then
      return dft
    else
      return val
    end
  end

  def self.initialize (*opts)
    db_user  = set_or_dft(opts[0])
    db_pass  = set_or_dft(opts[1])
    db_host  = set_or_dft(opts[2])
    db_name  = set_or_dft(opts[3])
    log_dir  = set_or_dft(opts[4],'/var/log/pdns-rest')
    loglevel = set_or_dft(opts[5], 'WARN')

    PDNS::config_log(log_dir, loglevel)

    @@log.info "using database #{db_name} on host #{db_host}"
    DataMapper.setup(:default, "mysql://#{db_user}:#{db_pass}@#{db_host}/#{db_name}")
    DataMapper.finalize

    @@log.info 'PDNS data mapping initialized'
  end

  def self.log
    return @@log
  end

end