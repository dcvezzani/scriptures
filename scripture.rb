#!ruby19
# encoding: utf-8

require 'oga'
require 'httpclient'
require 'debugger'
require 'json'

if(ARGV.length == 0)
  puts "USAGE: 
ruby scripture.rb 'https://www.lds.org/scriptures/bofm/mosiah/4.20,29-30'
ruby scripture.rb 'gen 1:15'
ruby scripture.rb 'philip 2:5'
  "
  exit
end

BOOKS = {"gen"=>["ot"], "ex"=>["ot"], "lev"=>["ot"], "num"=>["ot"], "deut"=>["ot"], "josh"=>["ot"], "judg"=>["ot"], "ruth"=>["ot"], "1-sam"=>["ot"], "2-sam"=>["ot"], "1-kgs"=>["ot"], "2-kgs"=>["ot"], "1-chr"=>["ot"], "2-chr"=>["ot"], "ezra"=>["ot"], "neh"=>["ot"], "esth"=>["ot"], "job"=>["ot"], "ps"=>["ot"], "prov"=>["ot"], "eccl"=>["ot"], "song"=>["ot"], "isa"=>["ot"], "jer"=>["ot"], "lam"=>["ot"], "ezek"=>["ot"], "dan"=>["ot"], "hosea"=>["ot"], "joel"=>["ot"], "amos"=>["ot"], "obad"=>["ot"], "jonah"=>["ot"], "micah"=>["ot"], "nahum"=>["ot"], "hab"=>["ot"], "zeph"=>["ot"], "hag"=>["ot"], "zech"=>["ot"], "mal"=>["ot"], "matt"=>["nt"], "mark"=>["nt"], "luke"=>["nt"], "john"=>["nt"], "acts"=>["nt"], "rom"=>["nt"], "1-cor"=>["nt"], "2-cor"=>["nt"], "gal"=>["nt"], "eph"=>["nt"], "philip"=>["nt"], "col"=>["nt"], "1-thes"=>["nt"], "2-thes"=>["nt"], "1-tim"=>["nt"], "2-tim"=>["nt"], "titus"=>["nt"], "philem"=>["nt"], "heb"=>["nt"], "james"=>["nt"], "1-pet"=>["nt"], "2-pet"=>["nt"], "1-jn"=>["nt"], "2-jn"=>["nt"], "3-jn"=>["nt"], "jude"=>["nt"], "rev"=>["nt"], "title-page"=>["nt"], "dc"=>["dc-testament"], "od"=>["dc-testament"], "introduction"=>["dc-testament", "pgp", "bofm"], "chron-order"=>["dc-testament"], "moses"=>["pgp"], "abr"=>["pgp"], "fac-1"=>["pgp"], "fac-2"=>["pgp"], "fac-3"=>["pgp"], "1"=>["pgp", "bofm"], "1-ne"=>["bofm"], "2-ne"=>["bofm"], "jacob"=>["bofm"], "mosiah"=>["bofm"], "alma"=>["bofm"], "hel"=>["bofm"], "3-ne"=>["bofm"], "morm"=>["bofm"], "ether"=>["bofm"], "moro"=>["bofm"], "bofm-title"=>["bofm"], "three"=>["bofm"], "eight"=>["bofm"], "js"=>["bofm"], "explanation"=>["bofm"], "illustrations"=>["bofm"], "pronunciation"=>["bofm"]}

if(ARGV[0] == 'books')
  puts JSON.dump(BOOKS)
  exit
end

scripture_ref = ARGV[0]

if(!scripture_ref.match(/^https*:/))
  md = scripture_ref.match(/^([\w\d-]+)[^\w\d-](.*)/)
  if(md and BOOKS.keys.flatten.uniq.include?(md[1]))
    scrip = BOOKS[md[1]].last
    verses = md[2].gsub(/:/, '.')
    scripture_ref = "https://www.lds.org/scriptures/#{scrip}/#{md[1]}/#{verses}"
  end
end

enum = Enumerator.new do |yielder|
  HTTPClient.get(scripture_ref) do |chunk|
    yielder << chunk
  end
end

document = Oga.parse_xml(enum)

class ElementNames
  attr_reader :names, :text, :cur_tag, :cur_class, :cur_uri

  def initialize
    @names = []
    @capture = false
    @text_cap = []
    @text = []
    @cur_tag = nil
    @cur_uri = []
    @cur_class = nil
  end

  def after_element(namespace, name, attrs = {})
    if(@capture and name == 'p')
      @text << @text_cap.join("")
      @text_cap = []
      @capture = false
    end
  end

  def on_element(namespace, name, attrs = {})
    @cur_tag = name
    @cur_class = attrs['class']
    if name == 'p' and attrs['class'] == 'highlight'
      @names << name 
      @capture = true
      @cur_uri << attrs['uri'] if attrs.include?('uri')
    end
  end

  def on_text(value)
    if @capture 
      if [nil, 'a', 'span'].include?(cur_tag) and (value.force_encoding("UTF-8").match(/\w/))

        if cur_class == 'verse'
          @text_cap << value.slice(0, value.length-1) + ". "
        else
          @text_cap << value
        end

      end
    end
    @cur_tag = nil
  end

  def reference
    # verses = cur.map{|x| x.match(/(\d+)$/)[1]}
    last_verse = nil
    refs = []
    cur_refs = []
    book = nil
    chapter = nil

    cur_uri.each do |u|
      md = u.match(/([^\/]+)\/(\d+)\.(\d+)$/)
      next if md.nil?

      book = md[1]
      chapter = md[2]
      verse = md[3].to_i

      # continue with current verse group
      if(last_verse.nil? or ((last_verse+1) == verse))
        cur_refs << verse

      # mark new verse group
      else
        if(cur_refs.length > 1)
          refs << "#{cur_refs.first}-#{cur_refs.last}"
        else
          refs << cur_refs.first
        end
        cur_refs = [verse]
      end
      
      last_verse = verse
    end

    # wrap up leftover data
    if(cur_refs.length > 1)
      refs << "#{cur_refs.first}-#{cur_refs.last}"
    else
      refs << cur_refs.first
    end

    "#{book.capitalize} #{chapter}:#{refs.join(",")}"
  end

  def xreference
    pos = []
    parts = cur_uri.first.split(/\//)
    pos << parts.pop.gsub(/\./, ":")
    book = parts.pop

    if(cur_uri.length > 1)
      parts = cur_uri.last.split(/\./)
      pos << parts.pop
    end

    "#{book.capitalize} #{pos.join('-')}"
  end
end

handler = ElementNames.new

Oga.sax_parse_xml(handler, document.to_xml)

# handler.names # => ["foo", "bar"]
# puts handler.cur_uri.join("\n")
puts "\n"
puts handler.reference
puts "\n"
puts handler.text.join("\n\n")


