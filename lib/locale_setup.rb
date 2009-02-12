module LocaleSetup
  extend self
  
  def perform!
    backport_features!
    configure!
    install_auto_reload!
  end
  
  def mono_locale!
    class << I18n
      def locale
        default_locale
      end
    end
  end
  
private

  def backport_features!
    I18n.module_eval {
      # I18n.locales
      unless respond_to? :locales
        class << self
          delegate :locales, :to => :backend
        end
        self::Backend::Simple.class_eval {
          def locales
            init_translations unless initialized?
            translations.keys
          end
        }
      end

      # I18n.reload!
      unless respond_to? :reload!
        class << self
          delegate :reload!, :to => :backend
        end
        self::Backend::Simple.class_eval {
          def reload!
            @initialized  = false
            @translations = nil
          end
        }
      end
    }
  end
  
  def configure!
    files = Dir["#{Rails.root}/app/locales/**/*.{rb,yml}"]
    I18n.load_path = I18n.load_path - files + files
    I18n.locale = I18n.default_locale
    Rails.logger.debug "** Loaded #{I18n.locales.size} locales: #{I18n.locales * ', '}"
  end
  
  def install_auto_reload!
    return unless Rails.version < '2.2.0'
    if !Rails.configuration.cache_classes
      require 'action_controller/dispatcher'
      ActionController::Dispatcher.to_prepare {
        LocaleSetup.configure!
        I18n.reload!
      }
    end
  end
end
