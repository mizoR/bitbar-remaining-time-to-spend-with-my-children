#!/usr/bin/env ruby
require 'erb'
require 'time'

module BitBar
  class INIFile
    Error = Class.new(StandardError)

    INIFileNotFound = Class.new(Error)

    SectionNotFound = Class.new(Error)

    def self.load(file = "#{ENV['HOME']}/.bitbarrc", base: {})
      raise INIFileNotFound if !File.exist?(file)

      parse(open(file, 'r:UTF-8') { |f| f.read })
    end

    def self.parse(source)
      # XXX: This implementation isn't correct, but will work in most cases.
      #      (Probably `StringScanner` will make code correct and clean.)
      sections = {}

      section = nil

      source.each_line do |line|
        if line =~ /^ *;/
          # comment
          next
        end

        if line =~ /^\[(.+)\]$/
          section = sections[$1.to_sym] = {}
          next
        end

        next unless section

        if line =~ /(.+?)=(.+)$/
          name  = $1.strip.to_sym
          value = $2.strip

          section[name] = value[/^"(.*)"$/, 1] || value[/^'(.*)'$/, 1] || value
          next
        end
      end

      new(sections: sections)
    end

    def initialize(sections:)
      @sections = sections
    end

    def fetch(name, *options)
      @sections.fetch(name.to_sym, *options)
    rescue KeyError
      raise SectionNotFound
    end
  end

  module RemainingTimeToSpendWithMyChildren
    ConfigurationError = Class.new(StandardError)

    class Children < Struct.new(:label,
                                :birthday,
                                :independence_day,
                                :hours_a_day_during_infant,
                                :hours_a_day_during_elementary,
                                :hours_a_day_during_junior_high_school,
                                :hours_a_day_during_high_school,
                                :hours_a_day_during_college_or_later)
      def self.from(children, options:)
        children.map do |child|
          base_keys = %i[
            label
            birthday
            independence_day
          ]

          option_keys = %i[
            hours_a_day_during_infant
            hours_a_day_during_elementary
            hours_a_day_during_junior_high_school
            hours_a_day_during_high_school
            hours_a_day_during_college_or_later
          ]

          Children.new(
            *base_keys.map {|key| child.fetch(key) },
            *option_keys.map {|key| options.fetch(key) },
          )
        end
      end

      # FIXME: Should consider "早生まれ".
      def remaining_hours
        hours = 0

        today = Date.today

        i = Date.new(birthday.year + 6, 4, 1)
        t = (i - today).to_i
        hours += t * hours_a_day_during_infant if t > 0

        e = Date.new(birthday.year + 12, 4, 1)
        t = (e - [i, today].max).to_i
        hours += t * hours_a_day_during_elementary if t > 0

        j = Date.new(birthday.year + 15, 4, 1)
        t = (j - [e, today].max).to_i
        hours += t * hours_a_day_during_junior_high_school if t > 0

        h = Date.new(birthday.year + 18, 4, 1)
        t = (h - [j, today].max).to_i
        hours += t * hours_a_day_during_high_school if t > 0

        t = (independence_day - [h, today].max).to_i
        hours += t * hours_a_day_during_college_or_later if t > 0

        hours
      end

      def remaining_days
        (independence_day - Date.today).to_i
      end
    end

    class View
      TEMPLATE = <<-EOT.gsub(/^ */, '')
        <%= @children[0].label %><%= @children[0].remaining_days %> days | font=courier color=<%= @text_color %>
        ---
        <% @children.each do |children| -%>
        <%= children.label %> <%= children.remaining_days %> days (<%= children.remaining_hours %> hours) | font=courier color=<%= @text_color %>
        <% end -%>
      EOT

      def initialize(children:, text_color:)
        @children = children
        @text_color = text_color
      end

      def render
        puts ERB.new(TEMPLATE, nil, '-').result(binding)
      end
    end

    class App
      DEFAULT_CONFIG = { text_color: 'black' }.freeze

      def initialize(config = {})
        @config = cast_config(DEFAULT_CONFIG.merge(config))
      end

      def run
        children = Children.from(@config.fetch(:children), options: @config)

        text_color = @config.fetch(:text_color)

        View.new(children: children, text_color: text_color).render
      end

      private

      def cast_config(config)
        config[:child_identifiers] = config.fetch(:child_identifiers).split(',')

        config[:children] = config[:child_identifiers].map do |identifier|
          label            = :"#{identifier}_label"
          birthday         = :"#{identifier}_birthday"
          independence_day = :"#{identifier}_independence_day"

          {
            label:            config.fetch(label),
            birthday:         Date.parse(config.fetch(birthday)),
            independence_day: Date.parse(config.fetch(independence_day))
          }
        end

        %i[
          hours_a_day_during_infant
          hours_a_day_during_elementary
          hours_a_day_during_junior_high_school
          hours_a_day_during_high_school
          hours_a_day_during_college_or_later
        ].each { |key| config[key] = config.fetch(key, 24).to_i }

        config
      rescue KeyError => e
        raise ConfigurationError, "Required key missing - #{e.message}"
      rescue ArgumentError
        raise ConfigurationError, 'Date format might be invalid.'
      end
    end
  end
end

if __FILE__ == $0
  begin
    config = BitBar::INIFile
      .load
      .fetch(:'remaining_time_to_spend_with_my_children', {})

    if File.exists?("#{ENV['HOME']}/.bitbarrc.local")
      local_config = BitBar::INIFile
        .load("#{ENV['HOME']}/.bitbarrc.local")
        .fetch(:'remaining_time_to_spend_with_my_children', {})

      config.merge!(local_config)
    end

    raise BitBar::INIFile::Error if config.empty?

    BitBar::RemainingTimeToSpendWithMyChildren::App.new(config).run
  rescue BitBar::INIFile::Error
    puts <<-EOM.gsub(/^ */, '')
      ⚠️
      ---
      To setup, create or edit your ~/.bitbarrc file with a new section, like:
      |
      [remaining_time_to_spend_with_my_children] | font=courier color=black
      ;# Required                                           | font=courier
      child_identifiers       = child0,child1               | font=courier
      child0_label            = ":girl:"                    | font=courier
      child0_birthday         = "2017-04-05+09:00"          | font=courier
      child0_independence_day = "2035-04-01+09:00"          | font=courier
      child1_label            = ":boy:"                     | font=courier
      child1_birthday         = "2019-04-05+09:00"          | font=courier
      child1_independence_day = "2037-04-01+09:00"          | font=courier
      |
      ;# Optional                                           | font=courier
      hours_a_day_during_infant             = 5             | font=courier
      hours_a_day_during_elementary         = 5             | font=courier
      hours_a_day_during_junior_high_school = 3             | font=courier
      hours_a_day_during_high_school        = 2             | font=courier
      hours_a_day_during_college_or_later   = 2             | font=courier
    EOM
  rescue BitBar::RemainingTimeToSpendWithMyChildren::ConfigurationError => e
    puts <<-EOM.gsub(/^ */, '')
      ⚠️
      ---
    #{e.message}
    EOM
  end
end
