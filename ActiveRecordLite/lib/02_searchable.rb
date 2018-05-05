require_relative 'db_connection'
require_relative '01_sql_object'
require 'byebug'
module Searchable
  def where(params)
  
    where_line = params.keys.map{|key| "#{key} = ?"}.join(" AND ")
    result = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM 
        #{self.table_name}
      WHERE 
        #{where_line}
    SQL
    result.map{ |el| self.new(el) }
  end
end

class SQLObject
  extend Searchable
end
