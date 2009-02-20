require 'test/unit'
require 'mocha'

require 'locale_check'

class LocaleCheckTest < Test::Unit::TestCase

# private

  def test_load_translations_in_file
    check = Class.new(LocaleCheck) { def initialize; end }.new
    check.stubs(:require)  
    I18n::Backend::Simple.stubs(:new).returns loader = stub
    loader.instance_eval { @translations = {:foo => :bar} }
    
    File.expects(:file?).with("foo.yml").once.returns true
    File.expects(:file?).with("foo.rb").once.returns true
    loader.expects(:load_translations).with("foo.yml").once
    loader.expects(:load_translations).with("foo.rb").once
    result = check.instance_eval { load_translations_in_file("foo.yml") }
    assert_equal({:foo => :bar}, result)
  end
end
