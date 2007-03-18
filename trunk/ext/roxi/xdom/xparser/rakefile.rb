task :build => [ 'xparser' ]
task :clean do
  GENERATED_FILES.each { | file | rm_f file }
end

SOURCE_FILES = FileList.new do | file_list |
  file_list.include 'unicode.rb',
    'rakefile.rb', 'extconf.rb', 'tc_xparser.rb',
    'pull_tokenizer.c', 'pull_tokenizer.h',
    'pull_parser.c', 'pull_parser.h',
    'xparser.c'
end

GENERATED_FILES = FileList.new do | file_list |
  file_list.include(
    FileList.new { | fl | fl.include '*' }.to_a - SOURCE_FILES.to_a
  )
end

file 'makefile' => [ 'extconf.rb' ] do
  ruby 'extconf.rb'
  sh 'mv Makefile makefile'
end

file 'unicode.h' => [ 'unicode.rb' ] do
  sh 'ruby unicode.rb > unicode.h'
end

file 'xparser' => [ 'unicode.h', 'xparser.c', 'makefile' ] do
  sh 'make'
end
