lds-scripture-books

require 'oga'
require 'httpclient'
require 'uri'
# require 'debugger'

scripture_ref = 'https://www.lds.org/scriptures/ot?lang=eng'

enum = Enumerator.new do |yielder|
  HTTPClient.get(scripture_ref) do |chunk|
    yielder << chunk
  end
end

document = Oga.parse_xml(enum)


document.xpath('people/person').each do |person|
  puts person.get('id') # => "1"

  # The "at_xpath" method returns a single node from a set, it's the same as
  # person.xpath('name').first.
  puts person.at_xpath('name').text # => "Alice"
end

books = {}

%w{https://www.lds.org/scriptures/ot?lang=eng
https://www.lds.org/scriptures/nt?lang=eng
https://www.lds.org/scriptures/dc-testament?lang=eng
https://www.lds.org/scriptures/pgp?lang=eng
https://www.lds.org/scriptures/bofm?lang=eng}.each do |scr_href|

  scr_uri = URI.parse(scr_href)
  scr_name = scr_uri.path.match(/([^\/]+)$/)[1]

  enum = Enumerator.new do |yielder|
    HTTPClient.get(scr_href) do |chunk|
      yielder << chunk
    end
  end

  document = Oga.parse_xml(enum)

  document.css('ul.books li a,ul.frontmatter li a,ul.backmatter li a').each do |book|
    uri = URI.parse(book.attributes.find{|x| x.name == "href"}.value)
    book_name = uri.path.match(/([^\/]+)$/)[1]
    
    books[book_name] = [] if books[book_name].nil?
    books[book_name] << scr_name unless books[book_name].include?(scr_name)
  end

end

href = document.css('ul.books li a').first.attributes.find{|x| x.name == "href"}.value
uri = URI.parse(href)


=begin

=> {"gen"=>"ot", "ex"=>"ot", "lev"=>"ot", "num"=>"ot", "deut"=>"ot", "josh"=>"ot", "judg"=>"ot", "ruth"=>"ot", "1-sam"=>"ot", "2-sam"=>"ot", "1-kgs"=>"ot", "2-kgs"=>"ot", "1-chr"=>"ot", "2-chr"=>"ot", "ezra"=>"ot", "neh"=>"ot", "esth"=>"ot", "job"=>"ot", "ps"=>"ot", "prov"=>"ot", "eccl"=>"ot", "song"=>"ot", "isa"=>"ot", "jer"=>"ot", "lam"=>"ot", "ezek"=>"ot", "dan"=>"ot", "hosea"=>"ot", "joel"=>"ot", "amos"=>"ot", "obad"=>"ot", "jonah"=>"ot", "micah"=>"ot", "nahum"=>"ot", "hab"=>"ot", "zeph"=>"ot", "hag"=>"ot", "zech"=>"ot", "mal"=>"ot", "matt"=>"nt", "mark"=>"nt", "luke"=>"nt", "john"=>"nt", "acts"=>"nt", "rom"=>"nt", "1-cor"=>"nt", "2-cor"=>"nt", "gal"=>"nt", "eph"=>"nt", "philip"=>"nt", "col"=>"nt", "1-thes"=>"nt", "2-thes"=>"nt", "1-tim"=>"nt", "2-tim"=>"nt", "titus"=>"nt", "philem"=>"nt", "heb"=>"nt", "james"=>"nt", "1-pet"=>"nt", "2-pet"=>"nt", "1-jn"=>"nt", "2-jn"=>"nt", "3-jn"=>"nt", "jude"=>"nt", "rev"=>"nt", "dc"=>"dc-testament", "od"=>"dc-testament", "moses"=>"pgp", "abr"=>"pgp", "fac-1"=>"pgp", "fac-2"=>"pgp", "fac-3"=>"pgp", "1"=>"bofm", "1-ne"=>"bofm", "2-ne"=>"bofm", "jacob"=>"bofm", "mosiah"=>"bofm", "alma"=>"bofm", "hel"=>"bofm", "3-ne"=>"bofm", "morm"=>"bofm", "ether"=>"bofm", "moro"=>"bofm"}

=> {"gen"=>["ot"], "ex"=>["ot"], "lev"=>["ot"], "num"=>["ot"], "deut"=>["ot"], "josh"=>["ot"], "judg"=>["ot"], "ruth"=>["ot"], "1-sam"=>["ot"], "2-sam"=>["ot"], "1-kgs"=>["ot"], "2-kgs"=>["ot"], "1-chr"=>["ot"], "2-chr"=>["ot"], "ezra"=>["ot"], "neh"=>["ot"], "esth"=>["ot"], "job"=>["ot"], "ps"=>["ot"], "prov"=>["ot"], "eccl"=>["ot"], "song"=>["ot"], "isa"=>["ot"], "jer"=>["ot"], "lam"=>["ot"], "ezek"=>["ot"], "dan"=>["ot"], "hosea"=>["ot"], "joel"=>["ot"], "amos"=>["ot"], "obad"=>["ot"], "jonah"=>["ot"], "micah"=>["ot"], "nahum"=>["ot"], "hab"=>["ot"], "zeph"=>["ot"], "hag"=>["ot"], "zech"=>["ot"], "mal"=>["ot"], "matt"=>["nt"], "mark"=>["nt"], "luke"=>["nt"], "john"=>["nt"], "acts"=>["nt"], "rom"=>["nt"], "1-cor"=>["nt"], "2-cor"=>["nt"], "gal"=>["nt"], "eph"=>["nt"], "philip"=>["nt"], "col"=>["nt"], "1-thes"=>["nt"], "2-thes"=>["nt"], "1-tim"=>["nt"], "2-tim"=>["nt"], "titus"=>["nt"], "philem"=>["nt"], "heb"=>["nt"], "james"=>["nt"], "1-pet"=>["nt"], "2-pet"=>["nt"], "1-jn"=>["nt"], "2-jn"=>["nt"], "3-jn"=>["nt"], "jude"=>["nt"], "rev"=>["nt"], "title-page"=>["nt"], "dc"=>["dc-testament"], "od"=>["dc-testament"], "introduction"=>["dc-testament", "pgp", "bofm"], "chron-order"=>["dc-testament"], "moses"=>["pgp"], "abr"=>["pgp"], "fac-1"=>["pgp"], "fac-2"=>["pgp"], "fac-3"=>["pgp"], "1"=>["pgp", "bofm"], "1-ne"=>["bofm"], "2-ne"=>["bofm"], "jacob"=>["bofm"], "mosiah"=>["bofm"], "alma"=>["bofm"], "hel"=>["bofm"], "3-ne"=>["bofm"], "morm"=>["bofm"], "ether"=>["bofm"], "moro"=>["bofm"], "bofm-title"=>["bofm"], "three"=>["bofm"], "eight"=>["bofm"], "js"=>["bofm"], "explanation"=>["bofm"], "illustrations"=>["bofm"], "pronunciation"=>["bofm"]}
=end
