module CsvMadness
  class LoadError < RuntimeError
  end
  
  class ColumnError < ArgumentError
  end
  
  class ForbiddenColumnNameError < ColumnError
  end
  
  class MissingColumnError < ColumnError
  end
  
  class ColumnExistsError < ColumnError
  end
end