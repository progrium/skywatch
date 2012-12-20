require 'fileutils'

module Skywatch
  include FileUtils

  def init(name="")
    fail if skywatch?
    mkdir '.skywatch'
    begin
      cd '.skywatch' do
        system "git init"
        puts `heroku create #{name}`
        fail if not $?.exitstatus.zero?
        puts `heroku addons:add sendgrid:starter`
        system "cp #{watcher_path}/* ."
        system "bundle install"
      end
      mkdir 'alerts' rescue nil
      mkdir 'checks' rescue nil
      system "echo '.skywatch' > .gitignore"
    rescue
      rm_rf '.skywatch'
    end
  end

  def watcher_path
    File.dirname(__FILE__)+"/watcher"
  end

  def skywatch?
    not Dir["./.skywatch"].empty?
  end

  def checks
    fail unless skywatch?
    Dir["./checks/*"].collect{|c| Check[c] }
  end

  def alerts
    fail unless skywatch?
    Dir["./alerts/*"].collect{|c| Alert[c] }
  end

  def check(name)
    fail unless skywatch?
    Check[Dir["./checks/*.#{name}"].first]
  end

  def alert(name)
    fail unless skywatch?
    Alert[Dir["./alerts/#{name}"].first]
  end

  def create_alert(name, interpreter)
    fail unless skywatch?
    fail if File.exist? "./alerts/#{name}"
    File.open("./alerts/#{name}", 'w') do |f|
      f.write "#!/usr/bin/env #{interpreter}\n"
      if interpreter == 'bash'
        f.write "set -e\n"
      end
      f.write "# Write your alert here"
    end
    alert(name)
  end

  def create_check(name, interval, interpreter)
    fail unless skywatch?
    fail if File.exist? "./checks/#{interval}.#{name}"
    File.open("./checks/#{interval}.#{name}", 'w') do |f|
      f.write "#!/usr/bin/env #{interpreter}\n"
      if interpreter == 'bash'
        f.write "set -e\n"
      end
      f.write "# Write your check here"
    end
    check(name)
  end

  def name
    fail unless skywatch?
    cd ".skywatch" do
      if not File.exist? 'name'
        name = `eval $(heroku apps:info -s | grep "^name=") && echo "$name"`.strip
        File.open('name', 'w') {|f| f.write(name) }
      end
      @@name ||= File.read('name')
    end
    @@name
  end

  def reset
    fail unless skywatch?
    cd ".skywatch" do
      puts `heroku restart`
    end
  end

  def monitor
    fail unless skywatch?
    cd ".skywatch" do
      exec "heroku logs -t -n 10"
    end
  end

  def stage
    fail unless skywatch?
    cd '.skywatch' do
      system 'git rm -f alerts/* > /dev/null 2>&1'
      system 'git rm -f checks/* > /dev/null 2>&1'
    end
    mkdir_p '.skywatch/alerts'
    mkdir_p '.skywatch/checks'
    system 'cp alerts/* .skywatch/alerts'
    system 'cp checks/* .skywatch/checks'
    commit
  end

  def commit
    fail unless skywatch?
    cd '.skywatch' do
      system 'git add .'
      if not `git status`.include? "nothing to commit"
        system 'git commit -m "skywatch commit"'
      end
    end
  end

  def deploy
    stage
    cd '.skywatch' do
      puts `git push heroku master`
    end
  end

  def destroy
    fail unless skywatch?
    puts `heroku apps:destroy #{name} --confirm #{name}`
    rm_rf '.skywatch'
  end

  class Script
    attr :path
    attr :name

    def self.[](path)
      self.new(path)
    end

    def initialize(path)
      @path = path
      @name = File.basename(path)
    end

    def enabled?
      File.executable? @path
    end

    def enable
      chmod File.stat(@path).mode | 0700, @path
    end

    def disable
      enable # since this is relative, force 0700
      chmod File.stat(@path).mode & ~0100, @path
    end

    def destroy
      rm @path
    end
  end

  class Check < Script
    attr :interval
    
    def initialize(path)
      interval, name = File.basename(path).split('.', 2)
      @path = path
      @name = name
      @interval = interval.to_i
    end
  end

  class Alert < Script
  end

end

