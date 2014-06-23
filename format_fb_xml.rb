 #encoding: UTF-8

require 'nokogiri'
require 'watir'
require 'yaml'
require './fb_bot_functions'

def process_file(file)
	doc = Nokogiri::XML(File.open("fb_generated/#{file}"))

	sentences_to_translate = {}

	doc.xpath("//fbt_string").each do |node|
		sentence = ''

		node.at_xpath('.//fbt_text').children.each do |c|
			if c.cdata?
				sentence += c.text
			else
				sentence += "{#{c['name']}}"
			end
		end

		sentences_to_translate[node['hash']] = sentence
	end

	language = doc.xpath("//fbt_string").first['locale'] 

	File.open("fb_parsed/#{file.split('.').first}.csv", "w+") do |f|
		f.puts "Language;Hash;Sentence"

	  sentences_to_translate.each_pair do |k, v|
	  	f.puts "#{language};#{k};#{v}"
	  end
	end
end

# Parses XML translations from FB
# Dir.entries("fb_generated/").each do |entry|
# 	process_file(entry) if entry =~ /.(?:xml)/
# end

def push_file_to_fb(browser, file)
	translations = {}
	locale = file.split('.').first.split(//).last(5).join('')
	i = 0

	File.open("fb_translated/#{file}", :encoding => "UTF-8").each do |line|
		if i > 0
			tokens = line.split(',')

			translations[tokens[1]] = tokens.last
		end

		i += 1
	end

	translations.each_pair do |k, v|
		browser.goto("https://www.facebook.com/translations/admin/?app=249377268519431&query=#{k}&loc=#{locale}")

		if (!browser.div(class: 'clearfix voting_row').exists?)
			browser.textarea(name: "translation").click
			browser.textarea(name: "translation").set(v)
			
			browser.wait_until(5) { browser.div(class: 'trans_bar_actions').button(name: "submit").exists? }
			
			# while browser.textarea(name: 'translation').text != v
			# 	browser.textarea(name: "translation").set(v)
			# end

			begin
				browser.div(class: 'trans_bar_actions').button(name: "submit").click
			rescue
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

	Dir.entries("fb_translated/").each do |entry|
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
