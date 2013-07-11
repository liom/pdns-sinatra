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
require 'data_mapper'
require 'ipaddr'

module PDNS
  class Domain
    include DataMapper::Resource

    storage_names[:default] = 'domains'

    property :id,               Serial,   :key => true
    property :name,             String,   :required => true, :length => 255
    property :master,           IPAddress
    property :last_check,       Integer
    property :type,             String,   :required => true, :length => 6
    property :notified_serial,  Integer
    property :account,          String,   :length => 40

    has n, :records, 'Record',
      :parent_key     => [ :id ],
      :child_key      => [ :domain_id ],
      :order          => [ :type.asc, :name.asc ]

  end
end