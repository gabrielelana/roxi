module Rake

  class RakeFile

    include FileUtils

    def initialize(root)
      check_dir(root)
      @root = root
    end

    def exec(task='')
      sh "cd #{@root}; rake #{task.to_s}"
    end

    private

    def check_dir(dir)
      raise "#{dir} is not a directory" if not File.directory?(dir)
    end

  end

end
