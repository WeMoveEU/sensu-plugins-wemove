#!/usr/bin/env ruby

require 'sensu-plugin/check/cli'

class CheckSidekiqLog < Sensu::Plugin::Check::CLI
  option :log_file,
         short: '-f PATH',
         long: '--log-file PATH',
         description: 'Log file to parse',
         required: true

  option :warning,
         description: 'Warning threshold, in number of identical errors',
         short: '-w THRESHOLD',
         long: '--warning THRESHOLD',
	 default: 0

  option :critical,
         description: 'Critical threshold, in number of identical errors',
         short: '-c THRESHOLD',
         long: '--critical THRESHOLD',
	 default: 10

  def run
    begin
      nb_errors = parse_log config[:log_file]
    rescue => e
      unknown "Could not open log file: #{e}"
    end

    if nb_errors > config[:critical].to_i
      critical alert_message(nb_errors)
    elsif nb_errors > config[:warning].to_i
      warning alert_message(nb_errors)
    else
      ok
    end
  end

  def parse_log(path)
    result = 0
    regexp = /WARN|ERROR/

    File.open path do |file|
      file.each_line do |line|
        if m = regexp.match(line)
          result += 1
        end
      end
    end
    result
  end

  def alert_message(count)
    "#{count} errors detected in log file"
  end

end
