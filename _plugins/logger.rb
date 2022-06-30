# Tee method
class TeeIO < IO
  def initialize orig, file
    @orig = orig
    @file = file
  end

  def write string
    @file.write string
    @orig.write Color.uncolor(string)
  end
end

module Jekyll
  class CECHooks
    class << self
      LOG_LEVELS = %i[error warning info debug].freeze
      LOG_COLORS = {
        normal: 'boldwhite',
        start: 'bg#a2bf8a black bold',
        command: 'bg#4c566b #eceff4 bold',
        console: 'bg#4c566b #c7cedb',
        action: '#eccc87',
        result: '#b58dae',
        failure: 'bg#9c202e boldwhite bold',
        warning: '#d2876d',
        success: '#a2bf8a',
        aux: '#b08fbf',
        finish: 'bg#a2bf8a boldwhite bold',
        timestamp: '#8ebcbb'
      }.freeze

      def log_message(msg, type: :normal, level: :log)
        return nil unless LOG_LEVELS.index(level.to_sym) <= DEBUG_CEC.to_i

        colors = []
        LOG_COLORS[type.to_sym].split(' ').each do |c|
          if c =~ /[bgf]*#[A-F0-9]{6}/i
            colors.push(Color.rgb(c))
          else
            colors.push(Color.send(c))
          end
        end
        height = TTY::Screen.height - 1
        msg = msg.split(/\n/).slice(0, height).join("\n")
        puts "#{colors.join('')}#{msg}#{Color.reset}"
        nil
      end

      def debug(msg, type: :normal)
        log_message(msg, type: type, level: :debug)
      end

      def info(msg, type: :normal)
        log_message(msg, type: type, level: :info)
      end

      def alert(msg, type: :normal)
        log_message(msg, type: type, level: :warning)
      end

      def error(msg, type: :normal)
        Util.errors.push(msg)
        log_message(msg, type: type, level: :error)
      end

      def border(msg)
        width = $stdout.winsize[1]
        ['-' * width, msg.strip, '-' * width].join("\n")
      end
    end
  end
end
