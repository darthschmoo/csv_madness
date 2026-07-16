module CsvMadness
  class Builder
    attr_accessor :label
    
    def initialize( &block )
      @columns = {}
      @column_syms = []

      @module = Module.new   # for extending
      self.extend( @module )
      yield self if block_given?
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

    # verbose: true - reports errors to stdout as they're encountered
    #
    # Three :on_error values:
    #    :print  => Put an error message in the cell instead of a value
    #    :raise  => Raise the error, halting the process
    #    :ignore => Hand back an empty cell
    # 
    # Although ideally it should be configurable by column...   
    def build( objects, build_opts: { :on_error => :print, :verbose => false } )
      spreadsheet = CsvMadness::Sheet.new( @column_syms )

      for object in objects
        STDOUT << "."
        record = {}
        for sym in @column_syms
          record[sym] = build_cell( object, sym, build_opts: build_opts )
        end

        spreadsheet.add_record( record )  # hash form
      end

      spreadsheet
    end

    def build_cell( object, sym, build_opts: { :on_error => :print } )
      column = @columns[sym]

      case column
      when String
        build_cell_by_pathstring( object, column, build_opts )
      when Proc
        build_cell_by_proc( object, column, build_opts )
      else
        "no idea what to do"
      end
    end

    def def( method_name, &block )
      @module.send( :define_method, method_name, &block )
    end

    protected
    def build_cell_by_pathstring( object, str, build_opts )
      handle_cell_build_error( :build_cell_by_pathstring, build_opts ) do
        for method in str.split(".").map(&:to_sym)
          object = object.send(method)
        end

        object
      end
    end

    def build_cell_by_proc( object, proc, build_opts )
      handle_cell_build_error( :build_cell_by_proc, build_opts ) do
        proc.call(object)
      end
    end
    
    def handle_cell_build_error( caller, build_opts, &block )
      begin
        yield
      end
    rescue Exception => e
      case build_opts[:on_error]
      when nil, :print
        puts "error #{e.message} #{caller}" if build_opts[:verbose]
        "ERROR: #{e.message} (#{caller}())"
      when :raise
        puts "Re-raisinge error #{e.message}.  Set build_opts[:on_error] to :print or :ignore if you want Builder to continue on errors."
        raise e
      when :ignore
        ""
      end
    end
  end
end
