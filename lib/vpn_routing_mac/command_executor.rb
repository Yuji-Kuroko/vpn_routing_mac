require "singleton"

class CommandExecutor
  include Singleton
  attr_accessor :verbose

  class CommandFailed < StandardError; end

  def instance
    @verbose = false
  end

  # execute command
  #
  # @param [String] command execute command
  # @param [Boolean] verbose log for the command
  # @param [Boolean] exception raise exception if the command failed
  def execute!(command, verbose: @verbose, exception: true)
    puts "cmd: #{command}" if verbose
    ret, err, status = Open3.capture3(command)

    raise CommandFailed.new(err) if exception && !status.success?

    ret
  end
end