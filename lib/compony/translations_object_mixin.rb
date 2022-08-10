module Compony
  # Methods defined in this mixin are injected into every Ruby Object, use with care
  # This woks similar to gettext_i18n_rails in HtmlSafeTranslations
  module TranslationsObjectMixin
    # Also make available on class methods
    def self.included(base)
      base.extend self
    end

    # Wrapper function for translations/internationalization.
    # If gettext_i18n_rails is used in the project, this is equivalent to calling `_()`
    # Otherwise, this falls back to returning the string as given.
    def compony_t(*args, **nargs, &block)
      if defined?(_)
        return _(*args, **nargs, &block)
        # To support more translation backends, add elsif here.
      else
        return args.first
      end
    end
  end
end
