require 'yaml'
require 'mysql'

def addReport(report)
  #runs
  puts "-----------------------"
  print report['run']["user"].strip, "-", report['run']["script_title"].strip, "-", report['run']["host"].strip, "-", report['run']["uri"].strip, "-", report['run']["version"].strip, "-", report['run']["start_time"].strip, "-", report['run']["end_time"].strip, "\n"

  puts "-----------------------"
  puts
  
  user = report['run']["user"].strip
  title = report ['run']["script_title"].strip
  host = report['run']["host"].strip
  uri = report['run']["uri"].strip
  version = report['run']["version"].strip
  start_time = report['run']["start_time"].strip
  end_time = report['run']["end_time"].strip
  
  conn.query( "INSERT INTO `runs` (user, title, host, uri, version, start_time, end_time ) VALUES ( '#{user}', '#{title}', '#{host}', '#{uri}', '#{version}', '#{start_time}', '#{end_time}' )")
  if conn.affected_rows = 1
    puts "Successfully added!"
  else
    puts "Could not be added!"
  end
  run_id = conn.insert_id()
  
  
  report['run']['parameters'].each do |parameter|
    key = parameter.keys.first
    value = parameter.values.first
    puts "#{key}: #{value}"
	conn.query( "INSERT INTO `parameters`(key, value, run_id ) VALUES (#{key}, #{value}, #{run_id})")
    if conn.affected_rows = 1
      puts "Successfully added!"
    else
      puts "Could not be added!"
    end
  end
  
  
  #files
  report['files'].each do |file|
	puts file.to_yaml
    unless file['basename']
      puts "Error: Obsolete report format."
      exit 1
    end
    
    identifier = "basename#{file['basename']}"
    identifier = "md5#{file['md5']}" if file['md5']
    puts identifier
	size = file['size'].to_i
  
    result = conn.query( "SELECT filecontent_id FROM filecontents WHERE identifier='#{identifier}' and size = '#{size}'")
  
    filecontent_id = nil
  
    if result.num_rows == 0
      conn.query("INSERT INTO `filecontents`(identifier, size) VALUES (#{identifier}, #{size})")
      if conn.affected_rows = 1
      puts "Successfully added!"
      else
      puts "Could not be added!"
      end
      filecontent_id = conn.insert_id()
    else
      filecontent_id = result.fetch_row['filecontent_id']
    end
    result = conn.query("SELECT filewithname_id, filecontent_id, basename, directory, ctime, mtime FROM filewithname WHERE filecontent_id='#{filecontent_id}', basename='#{basename}',directory='#{directory}', ctime='#{ctime}' and mtime='#{mtime}'")
  
  
    filewithname_id = nil
  
    if result.num_rows == 0
      conn.query("INSERT INTO `filewithname` (filecontent_id, basename, directory, ctime, mtime) VALUES (#{filecontent_id}, #{basename}, #{directory}, #{ctime}, #{mtime})")
      if conn.affected_rows = 1
        puts "Successfully added!"
      else
        puts "Could not be added!"
      end
      filewithname_id = conn.insert_id()
    else
      filewithname_id = result.fetch_row['filewithname_id']
    end

	input_file = file['input_file']
   conn.query("UPDATE run_filewithname SET run_id = #{run_id}, filewithname_id = #{filewithname_id}, input_file = #{input_file}")
  end
end

#Datenbankverbindung  
begin
	conn = Mysql.new("localhost" , "root" , "testen")
	conn.select_db("yaml")

	ARGV.each do |path|
	puts path
	report = YAML::load_file(path)
	addReport(report)
	end
rescue Mysql::Error => e
     puts "Error code: #{e.errno}"
     puts "Error message: #{e.error}"
     puts "Error SQLSTATE: #{e.sqlstate}"
	 exit 1
ensure
	conn.close
end
