require 'pry'
module Wovnrb

  class Store

    def initialize
      @settings = 
        {
          'user_token' => '',
          # 'url_pattern_name' => 'query'
          # 'url_pattern' => "?.*wovn=(?<lang>[^&]+)(&|$)",
          # 'url_pattern_name' => 'path'
          # 'url_pattern' => "/(?<lang>[^/.]+)(/|?|$)",
          'url_pattern_name' => 'subdomain',
          'url_pattern_reg' => "^(?<lang>[^.]+)\.",
          'query' => [],
          'backend_host' => 'rs1.wovn.io',
          'backend_port' => '6379',
        }
      @config_loaded = false
    end

    def get_settings
      if !@config_loaded
        if Rails.configuration.respond_to? :wovnrb
          @settings.merge!(Rails.configuration.wovnrb.stringify_keys)
          @settings['backend_port'] = @settings['backend_port'].to_s
        end
        user_token = @settings['user_token']
        #user_token = 'lYWQ9'
        redis_key = 'WOVN:BACKEND:SETTING::' + user_token
        cli = Redis.new(host: @settings['backend_host'], port: @settings['backend_port'])
        begin
          vals = cli.hgetall(redis_key) || {}
        rescue
          vals = {}
        end
        if vals.has_key?('query')
          vals['query'] = JSON.parse(vals['query'])
        end
        @settings.merge!(vals)
        @config_loaded = true
      end
      @settings
    end

    def get_values(url)
      #url = 'http://wovn.io'
      user_token = self.get_settings['user_token']
      #user_token = 'lYWQ9'
      redis_key = 'WOVN:BACKEND:STORAGE:' + url.gsub(/\/$/, '') + ':' + user_token
      request_values(redis_key)
      #f = File.open('./values/values', 'r')
      #return JSON.parse(f.read)
      #f.close
    end

    def request_values(key)
      cli = Redis.new(host: @settings['backend_host'], port: @settings['backend_port'])
      begin
        vals = cli.get(key) || '{}'
        vals = JSON.parse(vals)
      rescue
        vals = {}
      end
    end

  end

end
