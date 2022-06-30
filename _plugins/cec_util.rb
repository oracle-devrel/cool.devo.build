# frozen_string_literal: true

module Jekyll
  class CECHooks
    module Util
      class << self
        attr_accessor :meta
        ##
        ## Record a benchmark time
        ##
        ## @param      timer     [Symbol] The timer to record for (:total, :page, :operation)
        ## @param      position  [Symbol] :start or :finish
        ##
        def clock(timer, position = :start)
          raise 'Invalid timer' unless benchmark.keys.include?(timer.to_sym)

          raise "Invalid position argument #{position}, must be :start or :finish" unless position.to_s =~ /(start|finish)/

          benchmark[timer][position] = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end

        def timestamp(action)
          CECHooks.info("#{action} at #{Time.now.strftime('%F %T')}", type: :timestamp)
        end

        ##
        ## Report elapsed time for a timer
        ##
        ## @param      timer [Symbol] :total, :page, or :operation
        ##
        def report_bench(timer)
          raise 'Invalid timer' unless benchmark.keys.include?(timer.to_sym)

          seconds = benchmark[timer][:finish] - benchmark[timer][:start]
          humanize(seconds)
        end

        def print_bench(timer, border: true, title: nil, level: :debug, type: :timestamp)
          elapsed = report_bench(timer)
          msg = case timer
                when :total
                  "Site rendered in #{elapsed}"
                when :page
                  title ? "Page #{title} rendered in #{elapsed}" : "Page rendered in #{elapsed}"
                when :operation
                  title ? "Operation #{title} completed in #{elapsed}" : "Operation completed in #{elapsed}"
                end

          Jekyll::CECHooks.send(level.to_s, border ? Jekyll::CECHooks.border(msg) : msg, type: type)
        end

        class ::String
          ##
          ## Pluralize a string based on quantity
          ##
          ## @param      number  [Integer] the quantity of the
          ##                     object the string represents
          ##
          def to_p(number)
            number == 1 ? self : "#{self}s"
          end
        end

        ##
        ## Format seconds as a natural language string
        ##
        ## @param      seconds  [Integer] number of seconds
        ##
        ## @return [String] Date formatted as "X days, X hours, X minutes, X seconds"
        def humanize(seconds)
          s = seconds
          m = (s / 60).floor
          s = (s % 60).floor
          h = (m / 60).floor
          m = (m % 60).floor
          d = (h / 24).floor
          h = h % 24

          output = []
          output.push("#{d} #{'day'.to_p(d)}") if d.positive?
          output.push("#{h} #{'hour'.to_p(h)}") if h.positive?
          output.push("#{m} #{'minute'.to_p(m)}") if m.positive?
          output.push("#{s} #{'second'.to_p(s)}") if s.positive?
          output.join(', ')
        end

        def benchmark
          @benchmark ||= {
            total: { start: Process.clock_gettime(Process::CLOCK_MONOTONIC), finish: nil },
            page: { start: nil, finish: nil },
            operation: { start: nil, finish: nil }
          }
        end

        def pwd
          @pwd ||= Dir.pwd
        end

        def errors
          @errors ||= []
        end
      end
    end
  end
end
