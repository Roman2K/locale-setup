$: << File.dirname(__FILE__) + '/../lib'

desc "Verify the consistency of translation files"
task :check_locales do
  require 'locale_check'
  LocaleCheck.check_all
end
