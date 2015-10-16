require 'sequel'

DB = Sequel.sqlite(File.expand_path("#{ $project_root }/db/#{ENV['RACK_ENV']}.db", __FILE__))

class User < Sequel::Model
end

class Relationship < Sequel::Model
end 