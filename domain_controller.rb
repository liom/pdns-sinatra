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
require 'sinatra/base'
require 'json/pure'
require 'logger'
require 'PDNS'

class DomainController < Sinatra::Base

  def initialize(db_user, db_pass, db_host, db_name, env, log_dir, loglevel)
    @env = env

    PDNS.initialize(db_user, db_pass, db_host, db_name, log_dir, loglevel)
  end

  configure do
    # setting environment
    set :environment, @env

    # when running as a Rack app, ensure Sinatra does not start on its own
    set :run, false
  end

  def get_json(body)
    if body.empty? then
      status 400
      body 'no data in request'
      PDNS::log.warn 'body of request is empty'
      return nil
    end

    PDNS::log.debug "request body: \n#{body}"

    begin
      data = JSON.parse(body)
    rescue JSON::JSONError => e
      status 400
      body "could not parse data: #{body}"
      PDNS::log.warn "could not parse request body: #{e.message}\n #{body}"
      return nil
    end

    return data
  end

  def update_domain(name, data)
    PDNS::log.info("updating domain #{name}")

    domain = PDNS::Domain.first(:name => name)

    if !data.has_key?('type') then
      status 400
      body('type parameter is required for new domain registration')
      PDNS::log.warn 'request failed: no type parameter'
      return
    end

    if domain.nil? then
      PDNS::log.info "creating new domain of type #{data['type']}"
      domain = PDNS::Domain.create(
        :name     => name,
        :type     => data['type']
      )
    else
      PDNS::log.info "updating existing domain to type #{data['type']}"
      domain['type'] = data['type']
      if !domain.save then
        status 500
        body('save failed')
        PDNS::log.warn 'request failed: save failed'
        return
      end
    end
    status 200
    body (domain.id.to_s)

    PDNS::log.info "domain update succeeded"
  end

  def add_record(domain, rec_data)
    if !rec_data.has_key?('name') or !rec_data.has_key?('type') then
      body('name and type parameters are required for a record')
      PDNS::log.warn 'request failed: missing name or type'
      return false
    end
    record = domain.records.new
    %w(name type content ttl prio).each do |k|
      if rec_data.has_key?(k) then
        record[k] = rec_data[k]
      end
    end
    PDNS::log.info "name: #{rec_data['name']}, type: #{rec_data['type']}, content: #{rec_data['content']}, ttl: #{rec_data['ttl']}, prio: #{rec_data['prio']}"
    return true
  end

  def update_records(name, data)
    PDNS::log.info "updating records for domain #{name}"

    domain = PDNS::Domain.first(:name => name)

    if domain.nil? then
      status 404
      body('domain not found')
      PDNS::log.warn 'domain not found'
      return
    end

    PDNS::Record.transaction do |t|
      PDNS::log.debug 'started transaction'

      domain.records.all.destroy
      PDNS::log.debug "destroyed existing records for domain #{domain.name}"

      if data.has_key?('records') then
        PDNS::log.info "adding multiple records"
        data['records'].each { |rec_data|
          if !add_record(domain, rec_data) then
            t.rollback
            status 400
            return
          end
        }

      else
        PDNS::log.info 'setting single record'

        if !add_record(domain, data) then
          t.rollback
          status 400
          return
        end
      end
      if !domain.save then
        t.rollback
        status 500
        body ('could not save record')
        PDNS::log.warn 'request failed: could not save record'
      end
      t.commit
    end
  end

  put '/api/domain/:domain' do

    data = get_json request.body.read
    if data.nil? then
      return
    else
      update_domain params[:domain], data
    end

  end

  post '/api/domain/:domain' do

    data = get_json request.body.read
    if data.nil? then
      return
    else
      update_domain params[:domain], data
    end
    
  end

  put '/api/record/:domain' do

    data = get_json request.body.read

    if data.nil? then
      return
    else
      update_records params[:domain], data
    end
    
  end

  post '/api/record/:domain' do

    data = get_json request.body.read

    if data.nil? then
      return
    else
      update_records params[:domain], data
    end
    
  end
end