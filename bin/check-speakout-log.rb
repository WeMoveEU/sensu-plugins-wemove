#!/usr/bin/env ruby

require 'sensu-plugin/check/cli'

class CheckSpeakoutLog < Sensu::Plugin::Check::CLI
  option :log_file,
         short: '-f PATH',
         long: '--log-file PATH',
         description: 'Log file to parse',
         required: true

  option :ignore,
	 short: '-i REGEXP',
	 long: '--ignore REGEXP',
	 description: 'Pattern of log entries to ignore'

  option :warning,
         description: 'Warning threshold, in number of identical errors',
         short: '-w THRESHOLD',
         long: '--warning THRESHOLD',
	 default: 10

  option :critical,
         description: 'Critical threshold, in number of identical errors',
         short: '-c THRESHOLD',
         long: '--critical THRESHOLD',
	 default: 50

  def run
    begin
      result = parse_log config[:log_file]
    rescue => e
      unknown "Could not open log file: #{e}"
    end

    is_critical = false
    is_warning = false
    msgs = [];
    errors = result.keys.sort { |a, b| result[b][:count] <=> result[a][:count] }
    errors.each do |error|
      if result[error][:count] > config[:critical].to_i
	msgs << alert_message(error, result[error])
	is_critical = true
      elsif result[error][:count] > config[:warning].to_i
	msgs << alert_message(error, result[error])
	is_warning = true
      end
    end

    msg = msgs.join("\n")
    if is_critical
      critical msg
    elsif is_warning
      warning msg
    else
      ok
    end
  end

  def parse_log(path)
    result = {}
    regexp = /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} -([^-]*)-.*/
    ignore = if config[:ignore].nil? then nil else Regexp.new(config[:ignore]) end

    File.open path do |file|
      file.each_line do |line|
	if m = regexp.match(line) and (ignore.nil? or not(ignore =~ line))
	  error = m.captures.first.strip
	  details = result[error] || { count: 0 }
	  details[:count] += 1
	  result[error] = details
	end
      end
    end
    result
  end

  def alert_message(error, details)
    "Error #{error} occured #{details[:count]} times in log file"
  end

end
