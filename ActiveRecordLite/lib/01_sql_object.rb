require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  
  def self.columns
    @cols ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    @cols.first.map{ |el| el.to_sym }
  end

  def self.finalize!
    self.columns.each do |column|
      define_method column do 
        attributes[column]
      end
  
      define_method "#{column}=" do |value| 
        attributes[column] = value
      end
  
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= "#{self}".tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
    SQL
    self.parse_all(results)
  end

  def self.parse_all(results)
    objects = []
    results.each do |params|
      objects << self.new(params)
    end
    objects
  end

  def self.find(id)
    params = DBConnection.execute(<<-SQL, id)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
      WHERE
        id = ?
    SQL
    return nil if params.empty?
    object = self.new(params.first)
    
  end
  
  def initialize(params = {})
    columns = self.class.columns
    params.each do |key, value|
      key = key.to_sym
      unless columns.include?(key)
        raise "unknown attribute '#{key}'"
      end 
      self.send("#{key}=", value)
    end 
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |col|
      self.send(col)
    end 
  end

  def insert
    n = self.class.columns
    col_names = n.map(&:to_s).join(", ")
    question_marks = (["?"] * n.length).join(", ")
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    
    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names = self.class.columns.map do 
      |attr_name| "#{attr_name} = ?"
    end.join(", ")
    
    DBConnection.execute(<<-SQL, *attribute_values, self.id)
      UPDATE
        #{self.class.table_name}
      SET 
        #{col_names}
      WHERE
        id = ?
    SQL
  end

  def save
    self.id ? update : insert
  end
end

