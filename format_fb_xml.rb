 #encoding: UTF-8

require 'nokogiri'
require 'watir'
require 'yaml'
require './fb_bot_functions'

def process_file(file)
	doc = Nokogiri::XML(File.open("fb_generated/#{file}"))

	sentences_to_translate, sentence_contexts = {}, {}

	doc.xpath("//fbt_string").each do |node|
		sentence, context = '', ''

		node.at_xpath('.//fbt_text').children.each do |c|
			if c.cdata?
				sentence += c.text
			else
				sentence += "{#{c['name']}}"
			end
		end

		desc = node.at_xpath('.//fbt_description')

		if !desc.nil?
			node.at_xpath('.//fbt_description').children.each do |c|
				if c.cdata?
					context += c.text
				else
					context += "{#{c['name']}}"
				end
			end
		end

		sentences_to_translate[node['hash']] = sentence
		sentence_contexts[node['hash']] = context
	end

	language = doc.xpath("//fbt_string").first['locale'] 

	File.open("fb_parsed/#{file.split('.').first}.csv", "w+") do |f|
		f.puts "Language;Hash;Sentence;Context"

	  sentences_to_translate.each_pair do |k, v|
	  	f.puts "#{language};#{k};#{v};#{sentence_contexts[k]}"
	  end
	end
end

# Parses XML translations from FB
Dir.entries("fb_generated/").each do |entry|
	process_file(entry) if entry =~ /.(?:xml)/
end

# Grabs translations from original file and new sentences and merges files
orig, translations, orig_sentences, dest_sentences = {}, {}, {}, {}
context_sentence = {}
i = 0

File.open("GS_FB_2Translate_es_ES.csv", "r").each_with_index do |line, i|
	if i > 0
		tokens = line.split(',')
		
		translations[tokens[1].strip] = tokens.last.strip
		orig_sentences[tokens[2].strip] = tokens.last.strip		
	end
end

File.open("fb_parsed/FB_Exported_Translations.csv", "r").each_with_index do |line, i|
	if i > 0
		tokens = line.split(';')
		
		context = tokens.last.strip

		# discard infinitive
		if !(tokens[2] =~ /.ing | asked | sent /) && !(context =~ /.ing | asked | sent /)
			orig[tokens[1].strip] = tokens[-2].strip
			dest_sentences[tokens[1].strip] = tokens[-2].strip
			context_sentence[tokens[1].strip] = context
		end
	end
end

translated = 0

File.open("new_translated_es_ES.csv", "w") do |f|
	orig.each_pair do |key, value|
		translation = translations.has_key?(key) ? translations[key] : ''

		if translation.length == 0
			# First rule: try to get eventual translations that have on {GetSocial} and now are on {MeGusta} that is why
			# there is no match
			if dest_sentences[key] =~ /GetSocial C ac/
				sentence_to_translate = dest_sentences[key].gsub(/GetSocial C ac/, 'GetSocial')
				translation = orig_sentences[sentence_to_translate].gsub(/GetSocial/, 'GetSocial C ac') if orig_sentences.has_key?(sentence_to_translate)
			
				# Second rule: try to get eventual translations that do not have on {} and now are on {MeGusta} that is why
				# there is no match
				if translation.length == 0
					sentence_to_translate = dest_sentences[key].gsub(/ on \{GetSocial C ac\}/, '')
					translation = orig_sentences[sentence_to_translate].gsub(/\./, ' en {GetSocial C ac}.') if orig_sentences.has_key?(sentence_to_translate)		
				end
			end
		end

		f.puts 'es_ES' + ';' + key + ';' + orig[key] + ';' + context_sentence[key] + ';' + translation

		translated += 1 if translation.length > 0
	end
end

# def push_file_to_fb(browser, file)
# 	translations = {}
# 	locale = file.split('.').first.split(//).last(5).join('')
# 	i = 0

# 	File.open("fb_translated/#{file}", :encoding => "UTF-8").each do |line|
# 		if i > 0
# 			tokens = line.split(',')

# 			translations[tokens[1]] = tokens.last
# 		end

# 		i += 1
# 	end

# 	translations.each_pair do |k, v|
# 		browser.goto("https://www.facebook.com/translations/admin/?app=249377268519431&query=#{k}&loc=#{locale}")

# 		if (!browser.div(class: 'clearfix voting_row').exists?)
# 			browser.textarea(name: "translation").click
# 			browser.textarea(name: "translation").set(v)
			
# 			browser.wait_until(5) { browser.div(class: 'trans_bar_actions').button(name: "submit").exists? }
			
# 			# while browser.textarea(name: 'translation').text != v
# 			# 	browser.textarea(name: "translation").set(v)
# 			# end

# 			begin
# 				browser.div(class: 'trans_bar_actions').button(name: "submit").click
# 			rescue
# 			end
# 		end
# 	end
# end	

# begin
#   unless ARGV.size == 2
#     puts "ERROR: Please run the script as:"
#     puts "ruby format_fb_xml.rb fb_username fb_password"

#     exit
#   end

#   FbBotFunctions.browser = Watir::Browser.start("http://facebook.com/")

#   FbBotFunctions.login(ARGV[0], ARGV[1])

#   browser = FbBotFunctions.browser

#   begin
#     FbBotFunctions.browser.wait_until(5) { browser.div(:id, "u_0_0").exists? }

#   rescue Exception
#     puts "ERROR: The username/password is incorrect!"
#     browser.close

#     exit
#   end

# 	Dir.entries("fb_translated/").each do |entry|
# 		push_file_to_fb(browser, entry) if entry =~ /.(?:csv)/
# 	end

#   FbBotFunctions.logout

#   puts 'Yeah, it''s done!'

# rescue SystemExit

# rescue Exception => e
#   puts "ERROR: #{e.message}"
#   puts e.backtrace

# 	FbBotFunctions.logout
# end
