# name: localized-anonymous-cache
# version: 0.1

enabled_site_setting :localized_anonymous_cache_enabled

require_dependency "middleware/anonymous_cache"

class ::Middleware::AnonymousCache::Helper

  def anonymous_locale
    begin
      require 'http_accept_language' unless defined? HttpAcceptLanguage
      available_locales = supported_locales.map { |locale| locale.to_s.gsub(/_/, '-') }
      parser = HttpAcceptLanguage::Parser.new(@env["HTTP_ACCEPT_LANGUAGE"])
      parser.language_region_compatible_from(available_locales).gsub(/-/, '_')
    rescue
      I18n.default_locale
    end
  end

  def supported_locales
    # This is assuming that "SUPPORTED_LOCALES" would be added to the global settings. For now I've hardcoded in a fallback.
    @env.key?("SUPPORTED_LOCALES") && !@env["SUPPORTED_LOCALES"].strip.empty? ? @env["SUPPORTED_LOCALES"].split(',') : ['fa_IR', 'fr', 'en']
  end

  def cache_key
    # Todo: remove this.
    puts "CACHEKEY: ANON_CACHE_#{@env["HTTP_ACCEPT"]}_#{anonymous_locale}_#{@env["HTTP_HOST"]}#{@env["REQUEST_URI"]}|m=#{is_mobile?}|c=#{is_crawler?}|b=#{has_brotli?}"
    @cache_key ||= "ANON_CACHE_#{@env["HTTP_ACCEPT"]}_#{anonymous_locale}_#{@env["HTTP_HOST"]}#{@env["REQUEST_URI"]}|m=#{is_mobile?}|c=#{is_crawler?}|b=#{has_brotli?}"
  end

end

after_initialize do

  require_dependency 'application_controller'
  class ::ApplicationController
    def supported_locales
      GlobalSetting.respond_to?(:supported_locales) && !GlobalSetting.supported_locales.strip.empty? ? GlobalSetting.supported_locales.split(',') : ['fa_IR', 'fr', 'en']
    end

    private

    def locale_from_header
      begin
        require 'http_accept_language' unless defined? HttpAcceptLanguage
        available_locales = supported_locales.map { |locale| locale.to_s.tr('_', '-') }
        parser = HttpAcceptLanguage::Parser.new(request.env["HTTP_ACCEPT_LANGUAGE"])
        parser.language_region_compatible_from(available_locales).tr('-', '_')
      rescue
        I18n.default_locale
      end
    end
  end
end
