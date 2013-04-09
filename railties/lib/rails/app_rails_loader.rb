require 'pathname'

module Rails
  module AppRailsLoader
    RUBY = File.join(*RbConfig::CONFIG.values_at("bindir", "ruby_install_name")) + RbConfig::CONFIG["EXEEXT"]
    EXECUTABLES = ['bin/rails', 'script/rails']

    def self.exec_app_rails
      cwd   = Dir.pwd

      exe   = find_executable
      exe ||= find_executable_in_parent_path
      return unless exe

      contents = File.read(exe)

      # This is the Rails executable, let's use it
      if contents =~ /(APP|ENGINE)_PATH/
        exec RUBY, exe, *ARGV if find_executable
        Dir.chdir("..") do
          # Recurse in a chdir block: if the search fails we want to be sure
          # the application is generated in the original working directory.
          exec_app_rails unless cwd == Dir.pwd
        end

      # This is a Bundler binstub. Stop and explain how to upgrade.
      elsif exe =~ /bin\/rails$/ && contents =~ /This file was generated by Bundler/
        $stderr.puts <<-end_bin_upgrade_warning
Looks like your app's ./bin/rails is a stub that was generated by Bundler.

In Rails 4, your app's bin/ directory contains executables that are versioned
like any other source code, rather than stubs that are generated on demand.

Here's how to upgrade:

  bundle config --delete bin    # Turn off Bundler's stub generator
  rake rails:update:bin         # Use the new Rails 4 executables
  git add bin                   # Add bin/ to source control

You may need to remove bin/ from your .gitignore as well.

When you install a gem whose executable you want to use in your app,
generate it and add it to source control:

  bundle binstubs some-gem-name
  git add bin/new-executable

        end_bin_upgrade_warning

        Object.const_set(:APP_PATH, File.expand_path('config/application',  Dir.pwd))
        require File.expand_path('../boot', APP_PATH)
        require 'rails/commands'
      end
    rescue SystemCallError
      # could not chdir, no problem just return
    end

    def self.find_executable
      EXECUTABLES.find { |exe| File.exists?(exe) }
    end

    def self.find_executable_in_parent_path(path = Pathname.new(Dir.pwd).parent)
      EXECUTABLES.find do |exe|
        File.exists?(exe) || !path.root? && find_executable_in_parent_path(path.parent)
      end
    end
  end
end
