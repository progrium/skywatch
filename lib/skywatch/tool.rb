require 'fileutils'

module Skywatch
  include FileUtils

  def init(path, name="")
    fail if skywatch? path
    mkdir '.skywatch'
    begin
      cd '.skywatch' do
        system "git init"
        puts `heroku create #{name}`
        fail if not $?.exitstatus.zero?
      end
    rescue
      rm_rf '.skywatch'
    end
  end

  def skywatch?(path)
    not Dir["#{path}/.skywatch"].empty?
  end
end

