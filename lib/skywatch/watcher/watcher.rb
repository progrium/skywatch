require 'clockwork'
require 'fileutils'

include Clockwork
include FileUtils

Clockwork.configure do |config|
  config[:logger] = Logger.new(STDOUT)
  config[:logger].level = Logger::ERROR
end

def mark_pass(check);     chmod File.stat(check).mode & ~0003, check; end 
def mark_fail(check);     chmod File.stat(check).mode | 0007, check; end
def mark_alerted(check);  chmod File.stat(check).mode | 0070, check; end
def marked_alerted?(check)
  `stat -c %A #{check} | sed 's/......\\(.\\).\\+/\\1/'` == "x\n"
end
def executables(glob)
  Dir[glob].select {|path| File.executable? path }
end

mkdir_p 'output'

executables('checks/*').each do |check|
  interval, name = File.basename(check).split('.', 2)

  puts "loading check #{name} for every #{interval} seconds"
  every interval.to_i.seconds, name do
    
    puts "checking #{name} (#{File.stat(check).mode.to_s(8)})"
    `#{check} > output/#{name} 2>&1`

    status = $?.exitstatus
    if status.zero?
      mark_pass check
    else
      puts "   #{name} check failed with status #{status}"
      mark_fail check

      if not marked_alerted? check
        executables('alerts/*').each do |alert|
          puts "   sending #{File.basename(alert)} alert for #{name}"
          `cat output/#{name} | #{alert} #{name} #{status} > /dev/null 2>&1`
          
          if $?.exitstatus.zero?
            mark_alerted check 
          end
        end
      end

    end
  end # every

end
