require 'faraday'
require 'nokogiri'

def translate(node)
  node.remove_attribute('class')
  request = Faraday.new('http://localhost')
  response = request.post('/index.php', {
    source: 'en',
    target: 'es',
    text: node.to_s
  })
  response.body
end

sections_paths = []
host = 'https://doc.rust-lang.org/book'
response = Faraday.get "#{host}/ch00-00-introduction.html"
if response.status != 200
  raise Exception.new 'HTTP response error'
end

parsed_page = Nokogiri::HTML(response.body)

parsed_page.css('.section > li > a').each do |item|
  sections_paths << item['href']
end

sections_paths.each do |path|

  puts "Skyping #{path}..."
  if File.exist?("translated/#{path}")
    next
  end

  translated = ''
  puts "Requesting #{path}..."

  response = Faraday.get "#{host}/#{path}"
  if response.status != 200
    raise Exception.new 'HTTP response error'
  end
  parsed_page = Nokogiri::HTML(response.body)

  parsed_page.css('#content > main').children.each do |children|

    translated += "\n"
    case children.name
    when 'p'
      translated += translate children
    when 'pre'
      translated += children.to_s
    when 'blockquote'
      translated += translate children
    when 'h3'
      translated += translate children
    when 'h2'
      translated += translate children
    when 'h4', 'h5'
      translated += translate children
    when 'ul', 'ol'
      translated += translate children
    when 'img'
      translated += children.to_s
    when 'div'
      translated += children.to_s
    when 'text', 'comment'
      next
    else
      raise Exception.new "Undefined node type #{children.name}"
    end
  end

  file = File.new("translated/#{path}", 'w')
  file.write(translated)
  file.close

  exit 0

end