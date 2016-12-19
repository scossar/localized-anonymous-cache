# name: localized-anonymous-cache
# about: Allows the locale for anonymous users to be set from the accept-language header on forums that are using a CDN
# version: 0.1
# authors: scossar
# url: https://github.com/scossar/localized-anonymous-cache

enabled_site_setting :localized_anonymous_cache_enabled

# This plugin is a work in progress. It's goal is to make it possible to set the
# locale for anonymous Discourse users from their browser's accept-language header for
# forums that are using using a CDN. It is based on the assumption that "SUPPORTED_LOCALES"
# would be added to the Discourse global settings. For now, it is testing for the presence
# of the "SUPPORTED_LOCALES" global and then falling back to some hardcoded locales.

require_dependency "middleware/anonymous_cache"

class ::Middleware::AnonymousCache::Helper

  def supported_locales
    @env.key?("SUPPORTED_LOCALES") && !@env["SUPPORTED_LOCALES"].strip.empty? ? @env["SUPPORTED_LOCALES"].split(',') : ['ar', 'zh_CN', 'en']
  end

  # Parse the accept-language header, try to find a compatible locale from the
  # list of supported locales. If there isn't a supported locale, fallback to the
  # default locale.
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


  # Only add the locale key if there is a reason to break the cache. I'm assuming that this
  # only needs to be done for the initial request.
  def require_locale_key?(http_accept)
    /text\/html|application\/xhtml+xml|application\/xml/ =~ http_accept
  end

  def locale_key(http_accept)
    if require_locale_key? http_accept
      anonymous_locale
    end
  end

  def cache_key
    @cache_key ||= "ANON_CACHE_#{@env["HTTP_ACCEPT"]}_#{locale_key(@env["HTTP_ACCEPT"])}_#{@env["HTTP_HOST"]}#{@env["REQUEST_URI"]}|m=#{is_mobile?}|c=#{is_crawler?}|b=#{has_brotli?}"
  end

end

after_initialize do

  require_dependency 'application_controller'
  class ::ApplicationController

    # Possibly, this should test if a CDN is being used, if a CDN isn't being used,
    # it could allow all the available locales.
    def supported_locales
      GlobalSetting.respond_to?(:supported_locales) && !GlobalSetting.supported_locales.strip.empty? ? GlobalSetting.supported_locales.split(',') : ['ar', 'zh_CN', 'en']
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
