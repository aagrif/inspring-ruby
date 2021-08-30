module RelativeSchedule
  NEVER = Time.current + 1.year

  attr_writer :relative_schedule_type
  attr_writer :relative_schedule_number
  attr_writer :relative_schedule_day
  attr_writer :relative_schedule_hour
  attr_writer :relative_schedule_minute

  def schedule_errors
    case relative_schedule_type
    when "Minute"
      if relative_schedule_number.to_i <= 0
        return [:relative_schedule_number, "must have a positive value."]
      end
    when "Hour"
      if relative_schedule_number.to_i <= 0
        return [:relative_schedule_number, "must have a positive value."]
      elsif !relative_schedule_minute.to_i.between?(0, 59)
        return [:relative_schedule_minute, "must be a valid minute."]
      end
    when "Day"
      if relative_schedule_number.to_i <= 0
        return [:relative_schedule_number, "must have a positive value."]
      elsif !relative_schedule_hour.to_i.between?(0, 23)
        return [:relative_schedule_hour, "must have a value between 0 and 23."]
      elsif !relative_schedule_minute.to_i.between?(0, 59)
        return [:relative_schedule_minute, "must be a valid minute."]
      end
    when "Week"
      if relative_schedule_number.to_i <= 0
        return [:relative_schedule_number, "must have a valid value."]
      elsif !(%w(sunday monday tuesday wednesday thursday friday saturday)
              .include?(relative_schedule_day.downcase))
        return [:relative_schedule_day, "must have a day of week."]
      elsif !relative_schedule_hour.to_i.between?(0, 23)
        return [:relative_schedule_hour, "must have a value between 0 & 23."]
      elsif !relative_schedule_minute.to_i.between?(0, 59)
        return [:relative_schedule_minute, "must be a valid minute."]
      end
    else
      return [:relative_schedule_type, "must be one of minute, hour, day, week."]
    end

    [nil, nil]
  end

  def relative_schedule_type
    @relative_schedule_type || get_field_from_schedule_text(:relative_schedule_type)
  end

  def relative_schedule_number
    @relative_schedule_number || get_field_from_schedule_text(:relative_schedule_number)
  end

  def relative_schedule_day
    @relative_schedule_day || get_field_from_schedule_text(:relative_schedule_day)
  end

  def relative_schedule_hour
    @relative_schedule_hour || get_field_from_schedule_text(:relative_schedule_hour)
  end

  def relative_schedule_minute
    @relative_schedule_minute || get_field_from_schedule_text(:relative_schedule_minute)
  end

  def get_field_from_schedule_text(field)
    return nil if schedule.blank?
    tokens = schedule.split
    return nil if tokens.length < 2

    case tokens[0]
    when "Minute"
      md = schedule.match(/^Minute (\d+)$/)
      return nil if !(md && md[1])
      case field
      when :relative_schedule_type then "Minute"
      when :relative_schedule_number then md[1]
      end
    when "Hour"
      md = schedule.match(/^Hour (\d+) (\d+)$/)
      return nil if !(md && md[1] && md[2])
      case field
      when :relative_schedule_type then "Hour"
      when :relative_schedule_number then md[1]
      when :relative_schedule_minute then md[2]
      end
    when "Day"
      md = schedule.match(/^Day (\d+) (\d+):(\d+)$/)
      return nil if !(md && md[1] && md[2] && md[3])
      case field
      when :relative_schedule_type then "Day"
      when :relative_schedule_number then md[1]
      when :relative_schedule_hour then md[2]
      when :relative_schedule_minute then md[3]
      end
    when "Week"
      md = schedule.match(/^Week (\d+) (\S+) (\d+):(\d+)$/)
      return nil if !(md && md[1] && md[2] && md[3] && md[4])
      case field
      when :relative_schedule_type then "Week"
      when :relative_schedule_number then md[1]
      when :relative_schedule_day then md[2]
      when :relative_schedule_hour then md[3]
      when :relative_schedule_minute then md[4]
      end
    end
  end

  def form_schedule
    self.schedule = schedule_text
  end

  def schedule_text
    case relative_schedule_type
    when "Minute"
      "Minute #{relative_schedule_number}"
    when "Hour"
      "Hour #{relative_schedule_number} #{relative_schedule_minute}"
    when "Day"
      "Day #{relative_schedule_number} #{relative_schedule_hour}:#{relative_schedule_minute}"
    when "Week"
      "Week #{relative_schedule_number} #{relative_schedule_day} #{relative_schedule_hour}:#{relative_schedule_minute}"
    end
  end

  def get_wday(str)
    case str
    when "Sunday" then 0
    when "Monday" then 1
    when "Tuesday" then 2
    when "Wednesday" then 3
    when "Thursday" then 4
    when "Friday" then 5
    when "Saturday" then 6
    else 0
    end
  end

  def target_time(from_time = Time.current)
    return NEVER if schedule.blank?
    tokens = schedule.split
    return NEVER if tokens.length < 2

    case tokens[0]
    when "Minute"
      md = schedule.match(/^Minute (\d+)$/)
      return NEVER if !(md && md[1])
      from_time + 60 * md[1].to_i
    when "Hour"
      md = schedule.match(/^Hour (\d+) (\d+)$/)
      return NEVER if !(md && md[1] && md[2])
      # There is an error in the calculation for time that is in past.
      # The fix in 291aef7dc309db7b4dca00d08cf7f2413e8844d1 solves it.
      # But it creates some unreliable user scenarios if we have hourly messages
      # configured at different times.
      hours_from_now = md[1].to_i - 1
      epoch = (from_time + hours_from_now.hours).beginning_of_hour
      Chronic.parse "#{md[2]} minutes from now", now: epoch
    when "Day"
      md = schedule.match(/^Day (\d+) (\d+):(\d+)$/)
      return NEVER if !(md && md[1] && md[2] && md[3])
      # There is an error in the calculation for time that is in past.
      # The fix in 291aef7dc309db7b4dca00d08cf7f2413e8844d1 solves it.
      # But it creates some unreliable user scenarios if we have daily messages
      # configured at different times.
      days_from_now = md[1].to_i - 1
      epoch = days_from_now == 0 ? from_time : (from_time + days_from_now.days).beginning_of_day
      Chronic.parse "#{md[2]}:#{md[3]}", now: epoch
    when "Week"
      md = schedule.match(/^Week (\d+) (\S+) (\d+):(\d+)$/)
      return NEVER if !(md && md[1] && md[2] && md[3] && md[4])
      weeks_from_now = md[1].to_i - 1
      wday = get_wday(md[2])

      epoch = if wday > from_time.wday
        (from_time + weeks_from_now.weeks).beginning_of_day
      elsif wday == from_time.wday
        if from_time.hour > md[3].to_i
          (from_time + weeks_from_now.weeks).beginning_of_day
        elsif from_time.hour == md[3].to_i
          if from_time.min >= md[4].to_i
            (from_time + weeks_from_now.weeks).beginning_of_day
          else
            (from_time + weeks_from_now.weeks).beginning_of_day - 1
          end
        else
          (from_time + weeks_from_now.weeks).beginning_of_day - 1
        end
      else
        (from_time + weeks_from_now.weeks).beginning_of_day - 1
      end

      scheduled_time = Chronic.parse("#{md[2]} #{md[3]}:#{md[4]}", now: epoch)
      # Chronic does not handle past time well in case of week schedules.
      scheduled_time += 1.week if scheduled_time < from_time
      scheduled_time
    else
      NEVER
    end
  end
end
