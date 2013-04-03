# -*- coding: utf-8 -*-
require 'fileutils'
require 'erb'
require 'kramdown'
require 'moji'

include ERB::Util

def build_parsed_file(src, dst)
  page_name = src.gsub(Regexp.new('data/(.+)\.' + SRC_EXT), '\1')
  puts "build_parsed_file %s %s" % [src, dst]
  vars = parse_markdown_file(src)
  vars[:page_name] = page_name
  File.write(dst, vars.inspect)
end

def parse_markdown_file(src)
  lines = open(src) do |fp|
    fp.readlines
  end
  header_end = lines.index("}--\n")
  if header_end.nil? then
    vars = {scope: :private, title: ''}
    content = lines.join('')
  else
    header = lines.slice(0, header_end).join('') + "\n}"
    vars = eval(header)
    header_end = header_end + 1 if lines[header_end + 1] == "\n"
    content = lines.slice(header_end + 1, lines.size - header_end - 1).join('')
  end
  vars[:content] = content
  content.split("\n").each do |line|
    if /^# +(.+)$/ =~ line then
      title = $1
      vars[:title] = title
      break
    end
  end
  return vars
end

def build_html(src, dst, scope)
  print "build_page for %s %s %s" % [scope, src, dst]
  vars = load_parsed(src)
  if vars.nil? then
    html = ''
  elsif vars[:scope] == :public || scope == :private then
    html = build_htmlsource(vars, scope)
  else
    html = ''
  end
  if html.length == 0 then
    puts ' [not build]'
  else
    puts ''
  end
  File.write(dst, html)
end

def create_directory_index(dir, scope)
  if dir == '' then
    dir2 = '.'
    index_page_name = 'index'
  else
    dir2 = dir
    index_page_name = dir + '/index'
  end
  root_path = get_relative_path_to_root(index_page_name)
  sources = Dir::entries('data/' + dir2).sort.map do |f|
    if dir == '' then
      f2 = f
    else
      f2 = dir2 + '/' + f
    end
    if f == '.' || f == '..' || f == 'index.md' then
      ''
    elsif File::ftype('data/' + f2) == 'file' && /^(.+)\.md$/ =~ f2 then
      page_name = $1
      vars = load_from_page_name(page_name)
      if vars.nil? then
        ''
      elsif vars[:scope] == :public || scope == :private then
        linkpath = root_path + page_name + '.html'
        '[' + vars[:title] + '](' + linkpath + ') '
      else
        ''
      end
    elsif File::ftype('data/' + f2) == 'directory' then
      page_name = f2 + '/index'
      vars = load_from_page_name(page_name)
      if vars.nil? then
        ''
      elsif vars[:scope] == :public || scope == :private then
        linkpath = root_path + f + '/'
        '[' + vars[:title] + '](' + linkpath + ') '
      else
        ''
      end
    else
      ''
    end
  end
  return sources.join('')
end

def build_htmlsource(vars, scope)
  html = vars[:content]

  # URLの次の行にテキストがある場合
  html = html.gsub(/(\S)\n(https?:\/\/[-.%+\/=?_~#:a-zA-Z0-9]*)\n(\S)/, "\\1  \n[\\2](\\2)  \n\\3")
  html = html.gsub(/\n(https?:\/\/[-.%+\/=?_~#:a-zA-Z0-9]*)\n(\S)/, "\n[\\1](\\1)  \n\\2")

  # URLの次が空行の場合
  html = html.gsub(/(\S)\n(https?:\/\/[-.%+\/=?_~#:a-zA-Z0-9]*)\n\n/, "\\1  \n[\\2](\\2)\n\n")
  html = html.gsub(/\n(https?:\/\/[-.%+\/=?_~#:a-zA-Z0-9]*)\n\n/, "\n[\\1](\\1)\n\n")

  # 全角文字の中にある改行はつなげる。つなげないとブラウザで見たときに
  # 半角スペースが入ってしまうため。
  html = html.gsub(/(#{Moji.zen})\n(#{Moji.zen})/, "\\1\\2")

  toc = []
  html = html.gsub(/^(#+) +(.+) +\{#([-a-zA-Z0-9]+)\}$/) do
    toc.push([$1.length, $2, $3])
    $&
  end

  html = html.gsub(/^\{toc\}$/) do
    toc2 = toc.map do |h|
      '    ' * (h[0] - 2) + '- [' + h[1] + '](#' + h[2] + ")"
    end
    toc2.join("\n")
  end

  html = html.gsub(/^\{toc-ls\}$/) do
    dir = get_dir_from_page_name(vars[:page_name])
    create_directory_index(dir, scope)
  end

  html = html.gsub(/^-> ([-_.\/a-zA-Z0-9]+)\.md$/) do
    ref_name = $1
    ref_page_name = get_page_name_from_ref_name(vars[:page_name], ref_name)
    ref_vars = load_from_page_name(ref_page_name)
    if ref_vars.nil? then
      '-> < no title >'
    elsif ref_vars[:scope] == :public || scope == :private then
      title = ref_vars[:title]
      "<i>-> <a href=\"#{ref_name}.html\">#{title}</a></i>"
    else
      '-> < no title >'
    end
  end

  html = convert_md_to_html(html)
  vars[:content] = html

  vars[:relative_path] = get_relative_path_to_root(vars[:page_name])

  if scope == :private then
    template_file = 'etc/templates/private.html'
  else
    template_file = 'etc/templates/public.html'
  end
  template = File.read(template_file)
  ERB.new(template).result(binding)
end

def get_page_name_from_ref_name(curr_page_name, ref_name)
  ref_name # TODO
end

def get_dir_from_page_name(page_name)
  p = page_name.index('/')
  if p.nil? then
    ''
  else
    page_name.slice(0, p)
  end
end

def get_relative_path_to_root(page_name)
  slash_count = page_name.split(/\//).size - 1
  if slash_count <= 0 then
    './'
  else
    '../' * slash_count
  end
end

def convert_md_to_html(markdown)
  html = Kramdown::Document.new(markdown).to_html
  html = html.gsub(/<a href="(http[^"]+)">/, '<a href="\1" target="_blank">')
  return html
end

def load_from_page_name(page_name)
  parsed_fname = 'data/' + page_name + '.md_rb'
  if File.exists?(parsed_fname).! then
    src_fname = 'data/' + page_name + '.md'
    if File.exists?(src_fname).! then
      return nil
    end
    build_parsed_file(src_fname, parsed_fname)
  end
  load_parsed(parsed_fname)
end

def load_parsed(fname)
  return nil unless File.exists?(fname)
  eval(File.read(fname))
end

