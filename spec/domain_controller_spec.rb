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

require 'domain_controller'
require 'rack/test'
require 'mysql'

def app
  Rack::Builder.new do
    use Rack::Reloader, 0
    use Rack::ContentLength
    map '/' do
      run DomainController.new('test', 'test', 'localhost', 'pdns_test', 'test', nil, 'DEBUG')
    end
  end.to_app
end

describe 'Domain Service' do
  include Rack::Test::Methods

  before(:each) do
    @my = Mysql::new('localhost', 'test', 'test', 'pdns_test')
    res = @my.query('delete from domains;')
    res = @my.query('delete from records;')
  end

  it 'should report an error when no data is sent' do
    put '/api/domain/foo'
    last_response.status.should == 400
  end

  it 'should report an error when data is unparsable' do
    put '/api/domain/foo', 'not json', 'CONTENT_TYPE' => 'application/json'
    last_response.status.should == 400
    last_response.body.should include "could not parse data"
  end

  it 'should report an error when no type is specified' do
    put '/api/domain/foo', {'foo' => 'bar'}.to_json, 'CONTENT_TYPE' => 'application/json'
    last_response.status.should == 400
    last_response.body.should include "type parameter is required"
  end

  it 'should create domain and report success on put of new domain registration' do
    put '/api/domain/foo', {'type' => 'NATIVE'}.to_json, 'CONTENT_TYPE' => 'application/json'
    last_response.should be_ok
    res = @my.query('select * from domains where name="foo"')
    res.num_rows.should == 1
    domain = res.fetch_hash
    domain['name'].should == 'foo'
    domain['type'].should == 'NATIVE'
  end

  it 'should created domain and report success on post of new domain registration' do
    post '/api/domain/foo', {'type' => 'NATIVE'}.to_json, 'CONTENT_TYPE' => 'application/json'
    last_response.should be_ok
    res = @my.query('select * from domains where name="foo"')
    res.num_rows.should == 1
    domain = res.fetch_hash
    domain['name'].should == 'foo'
    domain['type'].should == 'NATIVE'
  end

  it 'should update the same domain record on multiple posts' do
    post '/api/domain/foo', {'type' => 'NATIVE'}.to_json, 'CONTENT_TYPE' => 'application/json'
    last_response.should be_ok
    post '/api/domain/foo', {'type' => 'NATIVE'}.to_json, 'CONTENT_TYPE' => 'application/json'
    last_response.should be_ok
    res = @my.query('select * from domains where name="foo"')
    res.num_rows.should == 1
  end

end

describe 'Record Service' do
  include Rack::Test::Methods

  before(:each) do
    @my = Mysql::new('localhost', 'test', 'test', 'pdns_test')
    res = @my.query('delete from domains;')
    res = @my.query('delete from records;')

    put 'api/domain/foo', {'type' => 'NATIVE'}.to_json, 'CONTENT_TYPE' => 'application/json'
  end

  it 'should report an error when no data is sent' do
    put '/api/record/foo'
    last_response.status.should == 400
  end

  it 'should report an error when data is unparsable' do
    put '/api/record/foo', 'not json', 'CONTENT_TYPE' => 'application/json'
    last_response.status.should == 400
    last_response.body.should include "could not parse data"
  end

  it 'should fail if the domain does not exist' do
    put '/api/record/bar',  
      {'name' => 'foo',
       'type' => 'MX',
       'content' => 'blah blah',
       'ttl' => 2000,
       'prio' => 25
      }.to_json, 'CONTENT_TYPE' => 'application/json'
    last_response.status.should == 404
    last_response.body.should include "domain not found"
  end

  it 'should fail if name or type is not supplied' do
    put '/api/record/foo', {'name' => 'some name'}.to_json, 'CONTENT_TYPE' => 'application/json'
    last_response.status.should == 400
    last_response.body.should include "name and type parameters are required for a record"

    put '/api/record/foo', {'type' => 'some type'}.to_json, 'CONTENT_TYPE' => 'application/json'
    last_response.status.should == 400
    last_response.body.should include "name and type parameters are required for a record"
  end

  it 'should add a single record' do
    put '/api/record/foo', 
      {'name' => 'foo',
       'type' => 'MX',
       'content' => 'blah blah',
       'ttl' => 2000,
       'prio' => 25
      }.to_json, 
      'CONTENT_TYPE' => 'application/json'
    last_response.should be_ok
    res = @my.query('select * from records where name="foo"')
    res.num_rows.should == 1
    domain = res.fetch_hash
    domain['name'].should == 'foo'
    domain['type'].should == 'MX'
    domain['content'].should == 'blah blah'
    domain['ttl'].to_i.should == 2000
    domain['prio'].to_i.should == 25
  end

  it 'should add a single record via post' do
    post '/api/record/foo', 
      {'name' => 'foo',
       'type' => 'MX',
       'content' => 'blah blah',
       'ttl' => 2000,
       'prio' => 25
      }.to_json, 
      'CONTENT_TYPE' => 'application/json'
    last_response.should be_ok
  end

  it 'should add multiple records' do
    put '/api/record/foo', 
      {'records' => [
          {
           'name' => 'foo',
           'type' => 'SOA',
           'content' => 'foo admin@foo 1',
           'ttl' => 2000,
           'prio' => 25            
          },
          {
           'name' => 'foo',
           'type' => 'MX',
           'content' => 'blah blah2',
           'ttl' => 2000,
           'prio' => 25            
          }
       ]
      }.to_json, 
      'CONTENT_TYPE' => 'application/json'
    last_response.should be_ok
    res = @my.query('select * from records where name="foo"')
    res.num_rows.should == 2
  end

  it 'should replace records on subsequent puts/posts' do
    put '/api/record/foo', 
      {'records' => [
          {
           'name' => 'foo',
           'type' => 'SOA',
           'content' => 'foo admin@foo 1',
           'ttl' => 2000,
           'prio' => 25            
          },
          {
           'name' => 'foo',
           'type' => 'MX',
           'content' => 'blah blah2',
           'ttl' => 2000,
           'prio' => 25            
          }
       ]
      }.to_json, 
      'CONTENT_TYPE' => 'application/json'
    last_response.should be_ok
    put '/api/record/foo', 
      {'records' => [
          {
           'name' => 'foo',
           'type' => 'SOA',
           'content' => 'foo admin@foo 1',
           'ttl' => 2000,
           'prio' => 25            
          },
       ]
      }.to_json, 
      'CONTENT_TYPE' => 'application/json'
    last_response.should be_ok
    res = @my.query('select * from records where name="foo"')
    res.num_rows.should == 1
  end
end