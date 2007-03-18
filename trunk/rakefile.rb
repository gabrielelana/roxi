require 'rake/contrib/rakefile'
require 'rake/testtask'

root = File.dirname(__FILE__)
xpath = Rake::RakeFile.new("#{root}/ext/roxi/xpath")
xparser = Rake::RakeFile.new("#{root}/ext/roxi/xdom/xparser");
bench = Rake::RakeFile.new("#{root}/bench")

desc 'build all extensions'
task :build do
  xpath.exec :build
  xparser.exec :build
end

desc 'clean all builded files'
task :clean do
  xpath.exec :clean
  xparser.exec :clean
end

desc 'exec all test cases'
task :tc => :test_case

desc 'exec all use cases'
task :uc => :use_case

desc 'exec benchmarks'
task :bench do
  bench.exec :bench
end

Rake::TestTask.new(:test_case) do | task |
  task.test_files = FileList.new('test/**/tc_*.rb');
end

Rake::TestTask.new(:use_case) do | task |
  task.test_files = FileList.new('use/**/uc_*.rb');
end
