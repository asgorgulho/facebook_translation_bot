require 'nokogiri'

def process_file(file)
	doc = Nokogiri::XML(File.open("xml_fb_generated/#{file}"))

	sentences_to_translate = {}

	doc.xpath("//fbt_string").each do |node|
		fbt_tokens = node.css("fbt_token")
		cdata = node.at_xpath('.//fbt_text').text.split(' ')
		sentence, i = [], 0

		begin
			sentence << "{#{fbt_tokens[i]['name']}}" if i < fbt_tokens.size

			if i < cdata.size
				sentence << cdata[i]	
			else
				break
			end

			i += 1
	  end while true

		sentences_to_translate[node['hash']] = sentence.join(' ').strip.gsub(/\s\./, '.') 
	end

	language = doc.xpath("//fbt_string").first['locale'] 

	File.open("xml_fb_parsed/#{file.split('.').first}.csv", "w+") do |f|
		f.puts "Language;Hash;Sentence"

	  sentences_to_translate.each_pair do |k, v|
	  	f.puts "#{language};#{k};#{v}"
	  end
	end
end

Dir.entries("xml_fb_generated/").each do |entry|
	process_file(entry) if entry =~ /.(?:xml)/
end