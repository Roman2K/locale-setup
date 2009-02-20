require 'active_support' unless defined? I18n

class LocaleCheck
  DIRECTORY = ENV['DIR'] || 'app/locales'
  
  def self.check_all
    base = ENV['BASE'] || determine_base
    Dir[DIRECTORY + '/**/*.{yml,rb}'].each { |file| new(file, base).perform }
  end
  
  def self.determine_base
    ['config/environment.rb', *Dir['config/initializers/*internationalization*']].
      reverse.
      map { |file| eval(File.read(file)[/(?:^|;)\s*(?:config\.i18n|I18n)\.default_locale\s*=\s*([^\s#]+)/, 1] || "") }.
      compact.
      first || :en
  end
  
  def initialize(file, base)
    @file, @base = file, base.to_sym
  end
  
  def perform
    return if structure_file == @file
    
    puts "\n-----#{" #{@file} | Based on #{@base.inspect} ".ljust 45, '-'}"
    
    if !File.exist?(structure_file)
      puts "Extraneous file"
      return
    end
    
    # Root?
    unless data.size == 1
      puts "More than one root"
    end
    root = data.values.first
    
    # Check for types and extraneous entries
    check1 = NodeCheck.new(root, structure).perform
    
    # Check for missing entries
    check2 =
      NodeCheck.new(structure, root,
        :check_types => false,
        :on_extraneous_entry => lambda { |entry| puts "Missing entry: #{entry}" }).perform
    
    puts ">> Entries: #{check1.size} | Errors: #{check1.errors + check2.errors}"
    
    return self
  end
  
private

  def data
    @data ||= load_translations_in_file(@file)
  end
  
  def structure_file
    @structure_file ||= @file.sub(/#{Regexp.escape DIRECTORY}\/[^\/\.]+/, "#{DIRECTORY}/#{@base}")
  end
  
  def structure
    @structure ||= load_translations_in_file(structure_file)[@base]
  end
  
  def load_translations_in_file(path)
    require 'i18n'
    loader = I18n::Backend::Simple.new
    [path, path.sub('.yml', '.rb')].each do |file|
      loader.load_translations(file) if File.file? file
    end
    loader.instance_eval('@translations')
  end
  
  class NodeCheck
    attr_reader :size
    attr_reader :errors
    
    def initialize(node, structure, options={}, namespace=[])
      @node, @structure, @options = node, structure, options
      
      # State
      @size   = 0
      @errors = 0
      @stack  = namespace.dup
      
      # Defaults
      @options[:check_types] = true unless @options.key?(:check_types)
      @options[:on_extraneous_entry] ||= lambda { |entry| puts "Extraneous entry: #{entry}" }
    end
    
    def perform
      @node.each do |key, value|
        @stack.push(key)
        begin
          process_entry(value)
        ensure
          @stack.pop
        end
        @size += 1
      end
      return self
    end
    
  private
  
    def current_entry_name
      @stack.join('.')
    end
    
    def process_entry(value)
      begin
        expected = find_value_at_same_level!
      rescue IndexError
        unless Hash === value
          @errors += 1
          @options[:on_extraneous_entry].call(current_entry_name)
        end
      else
        if @options[:check_types]
          unless types_match?(expected, value)
            @errors += 1
            puts "Types of '#{current_entry_name}' differ: #{value.class} instead of #{expected.class}"
          end
        end
      end
      if Hash === value
        child = NodeCheck.new(value, @structure, @options, @stack).perform
        @size += child.size
        @errors += child.errors
      end
    end
    
    def find_value_at_same_level!
      @stack.inject(@structure) do |tree, key|
        value = tree[key]
        raise IndexError if value.nil?
        value
      end
    end
    
    def types_match?(a, b)
      a.class === b || [a, b].any? { |val| Proc === val } || [a, b].all? { |val| [true, false].include? val }
    end
  end
end
