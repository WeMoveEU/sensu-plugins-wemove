#!/usr/bin/env ruby

require 'sensu-plugin/metric/cli'
require 'mysql'
require 'socket'
require 'inifile'

class CiviCRMGraphiteMailing < Sensu::Plugin::Metric::CLI::Graphite
  option :host,
         short: '-h HOST',
         long: '--host HOST',
         description: 'Mysql Host to connect to',
         required: true

  option :port,
         short: '-P PORT',
         long: '--port PORT',
         description: 'Mysql Port to connect to',
         proc: proc(&:to_i),
         default: 3306

  option :database,
	 short: '-d DATABASE',
	 long: '--database DATABASE',
         description: 'CiviCRM database',
	 default: nil

  option :username,
         short: '-u USERNAME',
         long: '--user USERNAME',
         description: 'Mysql Username'

  option :password,
         short: '-p PASSWORD',
         long: '--pass PASSWORD',
         description: 'Mysql password',
         default: ''

  option :ini,
         short: '-i',
         long: '--ini VALUE',
         description: 'My.cnf ini file'

  option :scheme,
         description: 'Metric naming scheme, text to prepend to metric',
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.mysql"

  option :socket,
         short: '-S SOCKET',
	 long: '--socket SOCKET'

  def run
    if config[:ini]
      ini = IniFile.load(config[:ini])
      section = ini['client']
      db_user = section['user']
      db_pass = section['password']
    else
      db_user = config[:username]
      db_pass = config[:password]
    end

    query = "SELECT COUNT(*) * 60 AS speed "\
      "FROM civicrm_mailing_job j "\
      "JOIN civicrm_mailing_event_queue q ON q.job_id=j.id "\
      "JOIN civicrm_mailing_event_delivered d ON d.event_queue_id=q.id "\
      "WHERE status='Running' AND time_stamp > DATE_ADD(NOW(), INTERVAL - 60 SECOND)"

    begin
      mysql = Mysql.new(config[:host], db_user, db_pass, config[:database], config[:port], config[:socket])
      result = mysql.query(query).fetch_row
    rescue => e
      puts e.message
    end

    output "#{config[:scheme]}.mailing.speed", result[0]

    mysql.close if mysql
    ok
  end

end
