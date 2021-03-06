class Headless
  class CliUtil
    def self.application_exists?(app)
      `which #{app}`.strip != ""
    end
    
    def self.ensure_application_exists!(app, error_message)
      if !self.application_exists?(app)
        raise Headless::Exception.new(error_message)
      end
    end

    def self.path_to(app)
      `which #{app}`.strip
    end

    def self.read_pid(pid_filename)
      pid = (File.read(pid_filename) rescue "").strip.to_i
      pid == 0 ? nil : pid
    end

    def self.fork_process(command, pid_filename, log_filename='/dev/null')
      pid = fork do
        STDERR.reopen(log_filename)
        exec command
        exit! 127 # safeguard in case exec fails
      end
      Process.detach(pid)

      File.open pid_filename, 'w' do |f|
        f.puts pid
      end
    end

    def self.kill_process(pid_filename, options={})
      if pid = self.read_pid(pid_filename)
        begin
          Process.kill 'TERM', pid
          Process.wait pid if options[:wait]
        rescue Errno::ECHILD
          # no such process; assume it's already killed
        rescue Errno::ESRCH
          # no such process; assume it's already killed
        end
      end
      
      begin
        FileUtils.rm pid_filename
      rescue Errno::ENOENT
        # pid file already removed
      end
    end
  end
end
