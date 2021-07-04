# frozen_string_literal: true

class Cdr::Base < Yeti::ActiveRecord
  self.abstract_class = true
  connects_to database: { writing: :cdr, reading: :cdr }

  DB_VER = LazyObject.new { db_version }
end
