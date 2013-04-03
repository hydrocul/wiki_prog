# -*- mode:ruby -*- -*- coding: utf-8 -*-

require 'rake/clean'
require './bin/build.rb'

DATA_DIR = 'data'
PUBLIC_DIR = 'public'
PRIVATE_DIR = 'private'
SRC_EXT = 'md'
PARSED_EXT = 'md_rb'
PUBLIC_TMP_EXT = 'public_html'
PRIVATE_TMP_EXT = 'private_html'
HTML_EXT = 'html'

PUBLIC_TMP_DSTS = FileList[DATA_DIR + '/**/*.' + SRC_EXT].ext(PUBLIC_TMP_EXT)
PRIVATE_TMP_DSTS = FileList[DATA_DIR + '/**/*.' + SRC_EXT].ext(PRIVATE_TMP_EXT)

desc "build html files for public"
task :default => [:build]

desc "clean and build"
task :rebuild => [:clobber, :build]

desc "publish html files for public and private"
task :publish => [:publish_public, :publish_private] do
  sh 'sh bin/data_push.sh'
end

desc "publish html files for public"
task :publish_public => [:build_public] do
  sh 'sh bin/public_push.sh'
end

desc "publish html files for private"
task :publish_private => [:build_private] do
  # TODO for private
end

desc "view diff before publish for public and private"
task :diff do
  sh 'sh bin/public_diff.sh' # TODO for private
end

desc "view diff before publish for public"
task :diff_public do
  sh 'sh bin/public_diff.sh'
end

desc "build html files for public and private"
task :build => [:build_public, :build_private]

desc "build html files for public"
task :build_public => PUBLIC_TMP_DSTS do
  FileList[PUBLIC_DIR + '/**/*.' + HTML_EXT].each do |f|
    src1 = f.gsub(Regexp.new('^' + PUBLIC_DIR + '/(.+)\\.' + HTML_EXT),
                  DATA_DIR + '/\1.' + SRC_EXT)
    if File.exists?(src1).! then
      rm f
    end
  end
  PUBLIC_TMP_DSTS.each do |src|
    dst = src.gsub(Regexp.new('^' + DATA_DIR + '/(.+)\.' + PUBLIC_TMP_EXT),
                   PUBLIC_DIR + '/\1.' + HTML_EXT)
    src_stat = File::stat(src)
    if src_stat.size == 0 then
      if File.exists?(dst) then
        rm dst
      end
    else
      if File.exists?(dst).! || File::stat(dst).mtime <= src_stat.mtime then
        unless File.exists?(File.dirname(dst)) then
          mkdir_p File.dirname(dst)
        end
        cp src, dst
      end
    end
  end
end

desc "build html files for private"
task :build_private => PRIVATE_TMP_DSTS do
  FileList[PRIVATE_DIR + '/**/*.' + HTML_EXT].each do |f|
    src1 = f.gsub(Regexp.new('^' + PRIVATE_DIR + '/(.+)\\.' + HTML_EXT),
                  DATA_DIR + '/\1.' + SRC_EXT)
    if File.exists?(src1).! then
      rm f
    end
  end
  PRIVATE_TMP_DSTS.each do |src|
    dst = src.gsub(Regexp.new('^' + DATA_DIR + '/(.+)\.' + PRIVATE_TMP_EXT),
                   PRIVATE_DIR + '/\1.' + HTML_EXT)
    src_stat = File::stat(src)
    if src_stat.size == 0 then
      if File.exists?(dst) then
        rm dst
      end
    else
      if File.exists?(dst).! || File::stat(dst).mtime <= src_stat.mtime then
        unless File.exists?(File.dirname(dst)) then
          mkdir_p File.dirname(dst)
        end
        cp src, dst
      end
    end
  end
end

rule '.' + PUBLIC_TMP_EXT => '.' + PARSED_EXT do |t|
  build_html(t.source.to_s, t.name, :public)
end

rule '.' + PRIVATE_TMP_EXT => '.' + PARSED_EXT do |t|
  build_html(t.source.to_s, t.name, :private)
end

rule '.' + PARSED_EXT => '.' + SRC_EXT do |t|
  build_parsed_file(t.source.to_s, t.name)
end

CLEAN.include(FileList[DATA_DIR + '/**/*.' + PUBLIC_TMP_EXT])
CLEAN.include(FileList[DATA_DIR + '/**/*.' + PRIVATE_TMP_EXT])
CLEAN.include(FileList[DATA_DIR + '/**/*.' + PARSED_EXT])
CLOBBER.include(FileList[PUBLIC_DIR + '/**/*.' + HTML_EXT])
CLOBBER.include(FileList[PRIVATE_DIR + '/**/*.' + HTML_EXT])


