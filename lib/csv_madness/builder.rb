module CsvMadness
  class Builder
    def initialize( &block )
      @columns = {}
      @column_syms = []
      @module = Module.new   # for extending
      self.extend( @module )
      yield self
    end

    def column( sym, method_path = nil, &block )
      warn( "#{sym} already defined. Overwriting." ) if @column_syms.include?( sym )
      
      @column_syms << sym
      @columns[sym] = if block_given?
                        block
                      elsif method_path
                        method_path
                      else
                        Proc.new(&sym)
                      end
    end

    # Three :on_error values:
    #    :print  => Put an error message in the cell instead of a value
    #    :raise  => Raise the error, halting the process
    #    :ignore => Hand back an empty cell
    # 
    # Although ideally it should be configurable by column...   
    def build( objects, opts = { :on_error => :print } )
      spreadsheet = CsvMadness::Sheet.new( @column_syms )

      for object in objects
        STDOUT << "."
        record = {}
        for sym in @column_syms
          record[sym] = build_cell( object, sym, opts )
        end

        spreadsheet.add_record( record )  # hash form
      end

      spreadsheet
    end

    def build_cell( object, sym, opts = { :on_error => :print } )
      column = @columns[sym]

      case column
      when String
        build_cell_by_pathstring( object, column, opts )
      when Proc
        build_cell_by_proc( object, column, opts )
      else
        "no idea what to do"
      end
    end

    def def( method_name, &block )
      @module.send( :define_method, method_name, &block )
    end

    protected
    def build_cell_by_pathstring( object, str, opts )
      handle_cell_build_error( :build_cell_by_pathstring, opts ) do
        for method in str.split(".").map(&:to_sym)
          object = object.send(method)
        end

        object
      end
    end

    def build_cell_by_proc( object, proc, opts )
      handle_cell_build_error( :build_cell_by_proc, opts ) do
        proc.call(object)
      end
    end
    
    def handle_cell_build_error( caller, opts, &block )
      begin
        yield
      end
    rescue Exception => e
      case opts[:on_error]
      when nil, :print
        puts "error #{e.message} #{caller}" if opts[:verbose]
        "ERROR: #{e.message} (#{caller}())"
      when :raise
        puts "Re-raisinge error #{e.message}.  Set opts[:on_error] to :print or :ignore if you want Builder to continue on errors."
        raise e
      when :ignore
        ""
      end
    end
  end
end
