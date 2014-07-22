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

def check_non_translated_sentences
	not_translated, translated = {}, {}

	Dir.entries("fb_non_translated/").each do |entry|
		if entry =~ /.(?:csv)/
			File.open("fb_non_translated/" + entry, "r").each_with_index do |line, i|
				next if i == 0

				tokens = line.split(';')

				not_translated[tokens[2].strip] = tokens[1].strip
			end
		end
	end

	translation_file = Dir.entries("fb_to_push/").first

	File.open("fb_to_push/" + translation_file, "r").each do |line|
		tokens = line.split(';')
		translated[tokens[1].strip] = tokens.last.strip if tokens.last.strip.length > 0
	end

	should_be_translated = {}

	not_translated.each_pair do |k, v|
		should_be_translated[not_translated[k]] = translated[k] if translated.key? k
	end

	File.open("fb_to_be_fixed/to_push_es_LA.csv", "w") do |f|
		should_be_translated.each_pair do |k, v|
			f.puts "#{k};;#{v}"
		end
	end
end

# Parses XML translations from FB
def parse_fb
	Dir.entries("fb_generated/").each do |entry|
		process_file(entry) if entry =~ /.(?:xml)/
	end
end

# Final process of merging translation and original app file
def generate_file_to_push(locale, app_title)
	hashes, translations = {}, {}
	file_title = app_title.gsub(' ', '').downcase.gsub(/\./, '')

	File.open("fb_parsed/#{file_title}_export_#{locale}.csv", "r").each_with_index do |line, i|
		if i > 0
			tokens = line.split(';')
			hashes[tokens[2].strip] = tokens[1].strip
		end
	end

	File.open("fb_translated/GS_FP_APP_TRANSLATION_#{locale}.csv", "r").each_with_index do |line, i|
		if i > 0
			tokens = line.split(';')
			translations[tokens[1].strip] = tokens[2].strip
		end
	end

	File.open("fb_to_push/#{file_title}_push_to_fb_#{locale}.csv", "w") do |f|
		hashes.each_pair do |k, v|
			tr = translations[k]

			if !translations.key?(k)
				tr = translations[k.gsub(/ on \{#{app_title}\}/, '')]
				tr ||= translations[k.gsub(/ on \{application\}/, '')]
			end

			if !tr.nil? && k =~ / on \{#{app_title}\}/ && !(tr =~  / on \{#{app_title}\}/)
				tr.gsub!(/\./, " en {#{app_title}}.")
			end

			if !tr.nil? && k =~ / on \{application\}/ && !(tr =~  / on \{application\}/)
				tr.gsub!(/\./, " en {application}.")
			end

			f.puts "#{v};#{k};#{tr}"
		end
	end
end

# parse_fb
# generate_file_to_push('es_ES', 'megusta.do')
# generate_file_to_push('es_LA', 'megusta.do')
# check_non_translated_sentences

def push_file_to_fb(browser, file)
	translations = {}
	locale = file.split('.').first.split(//).last(5).join('')
	i = 0

	File.open("fb_to_push/#{file}", :encoding => "UTF-8").each do |line|
		tokens = line.split(';')

		translations[tokens[1]] = tokens.last
	end

	translations.each_pair do |k, v|
		if v.strip.length > 0
			browser.goto("https://www.facebook.com/translations/admin/?app=742586302475822&query=#{k}&loc=#{locale}")
			if (!browser.div(class: 'clearfix voting_row').exists?)
				begin
					browser.textarea(name: "translation").click
					browser.textarea(name: "translation").set(v.strip)
					
					browser.wait_until(5) { browser.div(class: 'trans_bar_actions').button(name: "submit").exists? }
				
					browser.div(class: 'trans_bar_actions').button(text: "Translate").click

					sleep(0.5)

					if browser.link(class: 'layerCancel').exists?
						browser.textarea(name: "translation").set(v.strip)
					end
				rescue
				end
			else
				
			end
		end
	end
end	

begin
  unless ARGV.size == 2
    puts "ERROR: Please run the script as:"
    puts "ruby format_fb_xml.rb fb_username fb_password"

    exit
  end

  FbBotFunctions.browser = Watir::Browser.start("http://facebook.com/")

  FbBotFunctions.login(ARGV[0], ARGV[1])

  browser = FbBotFunctions.browser

  begin
    FbBotFunctions.browser.wait_until(5) { browser.div(:id, "u_0_0").exists? }

  rescue Exception
    puts "ERROR: The username/password is incorrect!"
    browser.close

    exit
  end

	Dir.entries("fb_to_push/").each do |entry|
		push_file_to_fb(browser, entry) if entry =~ /.(?:csv)/
	end

  FbBotFunctions.logout

  puts 'Yeah, it''s done!'

rescue SystemExit

rescue Exception => e
  puts "ERROR: #{e.message}"
  puts e.backtrace

	FbBotFunctions.logout
end
