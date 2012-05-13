require './lib/dtext.rb'
require 'nokogiri'

include DText

TestDir = "./tests"

def p(str)
  DText.parse(str).gsub! /[\n\s]+/, ""
end

def find_test()
  begin
    test = Dir.entries(TestDir).select { |f| f =~ /^[^\.](?=.*\.txt$)/ }
  rescue
    print "Read #{TestDir} error\n"
    return []
  end
  test.map! { |f|  "#{TestDir}/#{f}" }
  test.sort
end

def r(f)
  begin
    ct = File.read(f)
  rescue
    print "Read #{f} error\n"
    return ""
  end
  ct.strip
end

def h(f)
  Nokogiri::HTML::DocumentFragment.parse(r(f)).to_html.gsub! /[\n\s]+/, ""
end
