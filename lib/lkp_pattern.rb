#!/usr/bin/env ruby

LKP_SRC ||= ENV['LKP_SRC'] || File.dirname(__dir__)

require 'active_support/core_ext/string'
require "#{LKP_SRC}/lib/yaml"
require "#{LKP_SRC}/lib/lkp_path"

module LKP
  class Pattern
    attr_reader :regexp, :file

    def initialize(file)
      @file = file

      load
    end

    def contain?(content)
      return unless regexp

      content =~ regexp
    end

    def load
      @regexp = load_regular_expressions(file) if File.size?(file)
    end

    class << self
      def generate_klass(file_path)
        klass = Class.new(self) do
          include Singleton

          def initialize
            file_name = self.class.name.sub(/^LKP::/, '').underscore.dasherize
            super LKP::Path.src('etc', file_name)
          end
        end

        LKP.const_set File.basename(file_path).underscore.camelize, klass
      end
    end
  end

  class KeysPatterns
    def initialize(file)
      @keys_patterns = YAML.load_file file
      @keys_patterns = @keys_patterns.transform_values { |v| Regexp.new Array(v).join('|') }
    end

    def key(value)
      find = @keys_patterns.find { |_k, regexp| value =~ regexp }
      find && find.first
    end

    def value(key)
      @keys_patterns[key]
    end
  end

  # generate class like LKP::StatDenylist
  %w[event-counter-patterns dmesg-kill-pattern report-allowlist stat-allowlist stat-denylist oops-pattern perf-metrics-patterns].each do |file_name|
    LKP::Pattern.generate_klass(LKP::Path.src('etc', file_name))
  end
end
