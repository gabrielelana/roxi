task :build => [ 'parser.so' ]
task :clean do
  GENERATED_FILES.each { | file | rm_f file }
end
    
SOURCE_FILES = FileList.new do | file_list |
  file_list.include 'xpath.l', 'xpath.y', 'xpath.h',
    'extconf.rb', 'rakefile.rb', 'parser.c', 'parser.h'
end

GENERATED_FILES = FileList.new do | file_list |
  file_list.include(
    FileList.new { | fl | fl.include '*' }.to_a -
    SOURCE_FILES.to_a
  )
end

file 'xpath.yy.c' => [ 'xpath.l' ] do
  sh 'flex -oxpath.yy.c xpath.l'
end

file 'xpath.tab.c' => [ 'xpath.y' ] do
  sh 'yacc -d xpath.y'
end

file 'Makefile' => [ 'extconf.rb' ] do
  ruby 'extconf.rb'
end

file 'parser.so' => [ 'xpath.yy.c', 'xpath.tab.c', 'parser.c', 'Makefile' ] do
  sh 'make'
end
