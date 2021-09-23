module DateFilters

  # Returns a datetime if the input is a string
  def datetime(date)
    if date.class == String
      date = Time.parse(date)
    end
    date
  end

  # Returns an ordidinal date eg July 22 2007 -> July 22nd 2007
  def ordinalize(date)
    date = datetime(date)
    "#{date.strftime('%b')} #{ordinal(date.strftime('%e').to_i)}, #{date.strftime('%Y')}"
  end

  def timestamp(date)
    date = datetime(date)
    date.strftime('%s')
  end

  # Returns an ordinal number. 13 -> 13th, 21 -> 21st etc.
  def ordinal(number)
    if (11..13).include?(number.to_i % 100)
      "#{number}<span>th</span>"
    else
      case number.to_i % 10
      when 1; "#{number}<span>st</span>"
      when 2; "#{number}<span>nd</span>"
      when 3; "#{number}<span>rd</span>"
      else    "#{number}<span>th</span>"
      end
    end
  end

  # Format date and add time string
  def format_datetime(date, format)
    date_string = format_date(date, format)
    date = datetime(date)
    time_string = date.strftime('%-I:%M %p')
    %Q{#{date_string} at #{time_string}}
  end

  # Formats date either as ordinal or by given date format
  # Adds %o as ordinal representation of the day
  def format_date(date, format)
    date = datetime(date)
    if format.nil? || format.empty? || format == "ordinal"
      date_formatted = ordinalize(date)
    else
      date_formatted = date.strftime(format)
      date_formatted.gsub!(/%o/, ordinal(date.strftime('%e').to_i))
    end
    date_formatted
  end

  def check_sticky(date)
    date = datetime(date).strftime('%Y%m%d')
    return date == Time.now.strftime('%Y%m%d')
  end

  def iso(input)
    if input.is_a?(String)
      t = Time.parse(input)
    else
      t = input
    end

    if t
      t.iso8601
    else
      input
    end
  end

  Liquid::Template.register_filter self
end
