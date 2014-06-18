module FbBotFunctions
	@@browser
	@@app_url
	@@main_data = {}
	@@index = -1
	@@expression_translations = {}

	def self.browser; @@browser end
	def self.browser= b; @@browser = b end

	def app_url; @@app_url end
	def app_url= u; @@app_url = u end

	def main_data; @@main_data end
	def main_data= d; @@main_data = d end

	def expression_translations; @@expression_translations end
	def expression_translations= e; @@expression_translations = e end
	
	def retrieve_fb_data_from_file
		@@main_data = YAML.load_file("sample_fb_app/fb_data.yml")
	end

	def self.login(username, password)
		browser.text_field(:id, "email").set(username)
    browser.text_field(:id, "pass").set(password)
    browser.form(:id, "login_form").submit
	end

	def self.logout
	    begin
	      browser.goto("https://developers.facebook.com")
	      browser.form(:id, "logout_form").submit
	      browser.close

	    rescue Exception
	      browser.close
	    end
  	end

  	def add_type(name, type, is_generic)
  		browser.div(:id => "developer_app_body").link(:text => "#{type} Types").click

		unless browser.div(:class => "settingsContentContainer").link(:text, name).exists?
			browser.link(:text =>"Add #{type} Type").click

			browser.wait_until(5) { browser.button(:text => "Save").exists? }

			browser.text_field(:class, "_58al").set(name)

			sleep(1)

			browser.send_keys :return if is_generic

			sleep(1)

			browser.wait_until(5) { browser.button(:text => "Save").enabled? }
			browser.button(:text => "Save").click

			browser.wait_until(5) { browser.button(:text => "Save Changes").exists? }
		end
  	end

  	def add_story(action, object)
	    browser.div(:id => "developer_app_body").link(:text => "Stories").click
	
	    unless browser.link(:text, "#{action} a #{object}").exists?
			browser.link(:text =>"Add Custom Story").click

			browser.wait_until(5) { browser.select_list(:name, "action_type_id").present? }
			browser.wait_until(5) { browser.select_list(:name, "object_type_id").present? }

			browser.select_list(:name, "action_type_id").select(action)
			
			sleep(0.5)

			browser.select_list(:name, "object_type_id").select(object)
			
			browser.wait_until(5) { browser.button(:id => "create_button").enabled? }
			browser.button(:id => "create_button").click

			browser.wait_until(5) { browser.button(:name, "save_changes").exists? }
	    end
  	end

	def add_collection(action, what)
		browser.goto(app_url + "collections?ref=nav")

		sleep(1)

	    unless browser.link(:text, name).exists?
			browser.link(:text =>"Create a New Collection").click

			browser.wait_until(5) { browser.text_field(:id, "ogCreateCollectionTitle").exists? }

			browser.links(:class => "_42ft _4jy0 _55pi _55_p _p _4jy3 _517h")[0].click
			browser.ul(:class => "_54nf").lis(:class => "_54ni __MenuItem").each do |li|
				if li.span(:class => "_54nh").text == action
					li.click
					break
				end
			end

			sleep(1)

			browser.links(:class => "_42ft _4jy0 _55pi _55_p _p _4jy3 _517h")[1].click
			browser.uls(:class => "_54nf")[1].lis(:class => "_54ni __MenuItem").each do |li|
				if li.span(:class => "_54nh").text =~ /#{what}/
					li.click
					break
				end
			end

			browser.button(:text => "Create").click

			browser.wait_until(5) { browser.text_field(:name, "title").exists? }

			browser.goto(app_url + "collections?ref=nav")

			browser.wait_until(5) { browser.link(:class, "edit_item_link").exists? }

			browser.links(:class => "edit_item_link").last.click

			browser.wait_until(5) { browser.text_field(:name, "title").exists? }

			browser.execute_script("document.getElementById('u_0_3').setAttribute('class', '');")

			browser.radio(:value => 'gallery').set

			browser.input(:value => "Save Changes").click
		end
	end

	def fill_types
		type = "Object"
	
	    objects = main_data["open_graph"]["objects"]

	    objects.each { |i| FbBotFunctions.add_type(i.strip, type, false) }
	    ["object", "item"].each { |i| FbBotFunctions.add_type(i, type, true) }

	    type = "Action"

	    actions = main_data["open_graph"]["actions"]

    	actions.each { |i| FbBotFunctions.add_type(i.strip, type, false) }
    	FbBotFunctions.add_type("like", type, true)
	end

	def fill_stories
		stories = main_data["open_graph"]["stories"]

	    stories.each do |s|
	    	action, object = s.split('-')[0].strip, s.split('-')[1].strip

	    	FbBotFunctions.add_story(action.strip, object.strip)
		end
	end

	def fill_collections
		cols = main_data["open_graph"]["collections"]

	    cols.each do |s|
	    	action, what = s.split('-')[0].strip, s.split('-')[1].strip

	    	FbBotFunctions.add_collection(action, what)
		end
	end

	def fill_basic_info
		browser.div(:id => 'developer_app_nav').link(:text => 'Settings').click

		basic_info = main_data["basic_info"]

		browser.text_field(:name => "basic_name").set(basic_info["title"])
		browser.text_field(:name => "basic_namespace").set(basic_info["namespace"])
	    browser.text_field(:name => "basic_email" ).set(basic_info["contact"])

	    basic_info["domains"].each { |d| browser.text_field(:class => "_58al").set(d); browser.send_keys :return }

	    browser.wait_until(5) { browser.button(:name, "save_changes").enabled? }
	    browser.button(:name => "save_changes").click

	    unless browser.div(:class => "settingsContentContainer").span(:text => "App on Facebook").visible?
	    	browser.wait_until(5) { browser.div(:id => "add-platform-button").buttons.first.enabled? }
		    browser.div(:id => "add-platform-button").buttons.first.click

		    sleep(0.5)

		    browser.div(:text => "App on Facebook").click

		    sleep(0.5)
	    end

	    browser.text_field(:name => "canvas_url").set(basic_info["canv_url"])
	    browser.text_field(:name => "canvas_secure_url").set(basic_info["sec_canv_url"])

	    browser.wait_until(5) { browser.button(:name, "save_changes").enabled? }
	    browser.button(:name => "save_changes").click

	    sleep(1)

	    unless browser.div(:class => "settingsContentContainer").span(:text => "Website").visible?
	    	browser.wait_until(5) { browser.div(:id => "add-platform-button").buttons.first.enabled? }
		    browser.div(:id => "add-platform-button").buttons.first.click

		    sleep(1)

		    browser.div(:text => "Website").click

		    sleep(0.5)
		end

		browser.wait_until(5) { browser.button(:name, "save_changes").enabled? }
	    browser.text_field(:name => "site_url").set(basic_info["site_url"])

	    browser.wait_until(5) { browser.button(:name, "save_changes").enabled? }
		browser.button(:name => "save_changes").click	
	end

	def fill_developer_roles
		browser.div(:id => 'developer_app_nav').link(:text => 'Roles').click

		dev_roles = main_data["dev_roles"]

		dev_roles["fb_users"].each do |u|
			unless browser.div(:class => "roles_card").span(:text => /#{u}/).exists?
				browser.div(:id => 'developer_app_body').link(:text => 'Add Administrators').click
				browser.wait_until(5) { browser.div(:class, "uiOverlayFooter").exists? }

				browser.div(:class => "_59_m").text_field(:class => "_58al").set(u)
				browser.send_keys :return
				
				browser.wait_until(5) { browser.div(:class, "uiOverlayFooter").buttons.first.enabled? }
				browser.div(:class, "uiOverlayFooter").buttons.first.click
			end
		end
  	end

  	def fill_app_details
  		browser.div(:id => 'developer_app_nav').link(:text => 'App Details').click

  		app_details = main_data["app_details"]
  		app_info_data_tags = ["tagline", "desc"]
  		app_contact_data_tags = ["policy_url", "tos_url", "support_email", "support_url"]
  		app_info_area_tags = ["detailed_desc", "explain_perm"]

	    app_info_input_names = ["app_details_subtitle", "app_details_short_desc"]
	    app_contact_input_names = ["app_details_privacy_policy_url", "app_details_terms_of_service_url", "app_details_user_support_email", "app_details_user_support_url"]
	    app_info_area_names = [ "app_details_long_desc", "app_details_gdp_desc"]

   		length = app_info_input_names.size
   		(0...length).each { |i| browser.text_field(:name => app_info_input_names[i]).set(app_details[app_info_data_tags[i]]) }
	
	    browser.div(:id => "app_details_category").links.first.click
	    browser.wait_until(5) { browser.div(:class, "uiScrollableAreaContent").exists? }
	    browser.div(:class, "uiScrollableAreaContent").li(:text => app_details["category"].strip).click

	    length = app_contact_input_names.size
   		(0...length).each { |i| browser.text_field(:name => app_contact_input_names[i]).set(app_details[app_contact_data_tags[i]]) }

   		length = app_info_area_tags.size
   		(0...length).each { |i| browser.textarea(:name => app_info_area_names[i]).set(app_details[app_info_area_tags[i]]) }

	    upload_files

	    browser.wait_until(5) { browser.button(:name => "save_changes").enabled? }
	    browser.button(:name => "save_changes").click
	end

  	def upload_files
  		begin
	  		files = []

	  		Dir.entries("sample_fb_app/").each do |entry|
	 			files << entry if entry =~ /.(?:jpe?g|png|gif)/
	 		end

	  		divs = browser.divs(:class => "_2uh")

	  		files.sort!

	  		(0...files.size).each do |i|
	  			divs[i].link.click
	  		
	  			browser.wait_until(5) { browser.file_field(:name, "image_upload").exists? }

		   		browser.file_field(:name, "image_upload").set(File.absolute_path("sample_fb_app/#{files[i]}"))

		   		sleep(1)

	   			browser.form(:class, "_s").submit if browser.form(:class, "_s").exists?
			end
		rescue Exception => e
			return
		end
  	end

  	def fill_localize
  		browser.div(:id => 'developer_app_nav').link(:text => 'Localize').click

  		begin
  			languages = main_data["localize"]

	  		languages.each do |language|
	  			browser.div(:id => 'developer_app_body').link(:text => 'Add Language').click

				if browser.link(:id => "selectLanguageButton").exists?
					browser.link(:id => "selectLanguageButton").click
				else
					browser.link(:text => "Add Language").click
				end
		
		    sleep(1)

		    browser.link(:text => "All Languages").click
		
		    found_link = nil

		    browser.table(:class, 'localeList').rows.each do |row|
	      		row.cells.each do |cell|
	        		cell.ul(:class => "uiList _4kg").links.each do |link|
	      				found_link = link if link.attribute_value("aria-label") == language["language"]["name"]
		          		break if found_link
		        	end
		        	break if found_link
	  			end
	      		break if found_link
		    end

		    if found_link
		    	script = "return arguments[0].setAttribute('class', '')"
					browser.execute_script(script, found_link)

					found_link.click
		    end
	    end
			rescue Exception => e
				puts "WARNING: #{e.message}"
				return
			end
  	end

  	def retrieve_translations_from_file(lang)
	    general_translations, base_expression_translations = {}, {}
	
	    File.open("sample_fb_app/fb_action_translations_#{lang}.csv").each do |line|
				tokens = line.split(';')

				tokens[0].gsub!('application', main_data['basic_info']['title'].strip)
				tokens[1].gsub!('application', main_data['basic_info']['title'].strip)

				general_translations[tokens[0].strip] = tokens[1].strip
	    end

	    File.open("sample_fb_app/expression_translations_#{lang}.csv").each do |line|
				tokens = line.split(';')

				tokens[0].gsub!('application', main_data['basic_info']['title'].strip)
				tokens[1].gsub!('application', main_data['basic_info']['title'].strip)

				base_expression_translations[tokens[0].strip] = tokens[1].strip
	    end

	    # complement translations regarding new actions	    
	    expression_translations = {}
	    base_tenses = main_data['open_graph']['wish']['en']
	    translated_base_tenses = main_data['open_graph']['wish'][lang]

	    main_data['open_graph']['actions'].each do |action|
	    	if (action != 'Wish' && action != 'Recommend' && action != 'Get')
	    		action = action.downcase
		    	base_action_tenses = main_data['open_graph'][action]['en']
		    	translated_action_tenses = main_data['open_graph'][action][lang]

		    	puts translated_action_tenses

		    	base_expression_translations.each_pair do |k, v|
		    		k = k.gsub(/\b#{base_tenses[0]}\b/, base_action_tenses[0]).gsub(/\b#{base_tenses[0].capitalize}\b/, base_action_tenses[0].capitalize)
		    		k = k.gsub(/\b#{base_tenses[1]}\b/, base_action_tenses[1]).gsub(/\b#{base_tenses[1].capitalize}\b/, base_action_tenses[1].capitalize)
		    		k = k.gsub(/\b#{base_tenses[2]}\b/, base_action_tenses[2]).gsub(/\b#{base_tenses[2].capitalize}\b/, base_action_tenses[2].capitalize)

		    		v = v.gsub(/\b#{translated_base_tenses[0]}\b/, translated_action_tenses[0]).gsub(/\b#{translated_base_tenses[0].capitalize}\b/, translated_action_tenses[0].capitalize)
		    		v = v.gsub(/\b#{translated_base_tenses[1]}\b/, translated_action_tenses[1]).gsub(/\b#{translated_base_tenses[1].capitalize}\b/, translated_action_tenses[1].capitalize)
		    		v = v.gsub(/\b#{translated_base_tenses[2]}\b/, translated_action_tenses[2]).gsub(/\b#{translated_base_tenses[2].capitalize}\b/, translated_action_tenses[2].capitalize)

		    		expression_translations[k] = v
					end
		    end
	   	end

	   	@@expression_translations = expression_translations

	    general_translations
  	end

  	def write_translations_to_file(app_id, lang_name, lang_code)
    	app_url = "https://www.facebook.com/translations/admin/dashboard/?app=#{app_id}"

    	sentences, translations = [], []

  		browser.goto(app_url)

    	browser.link(:text => lang_name).click

    	sleep(1)

    	# Scrolls until the end in order to load all elements
    	(0..10).each do |i|
    		browser.execute_script("window.scrollTo(0,document.body.scrollHeight);")
    		sleep(1)
    	end

    	browser.divs(:class => "_50v7").each do |div|
    		sentences << div.text
    	end

    	browser.spans(:class => "_50u-").each do |span|
    		translations << span.text
    	end
	
    	File.open("sample_fb_app/fb_action_translations_#{lang_code}.csv", 'w') do |f|
      		(0...sentences.size).each do |i|
        		f.puts "#{sentences[i]};#{translations[i]}"
      		end
			end
  	end

  	def translate_sentences(app_id, lang, translations)
  		app_url = "https://www.facebook.com/translations/admin/?app=#{app_id}&loc=#{lang}"
  		browser.goto(app_url)

  		browser.windows.last.use do
	    	# Scrolls until the end in order to load all elements
	    	(0..10).each do |i|
	    		browser.execute_script("window.scrollTo(0,document.body.scrollHeight);")
	    		sleep(1)
	    	end

	    	# Clicks on the sentence to be available for translation
	    	browser.divs(:class => "_50v3").each do |div|
	    		key = div.div(:class => "_50v7").text

	    		div.click if !translations[key].nil? || !expression_translations[key].nil?
	    	end

	    	# Submits translation
	    	browser.divs(:class => "_50v4").each do |div|
	    		key = div.span(:class => "_55gv").text

	    		if !translations[key].nil? && translations[key].length > 0
	    			if div.textarea(:name => "translation").present?
		    			div.textarea(:name => "translation").set(translations[key])
		    			div.button(:name => "submit").click
		    		end
		    	elsif !expression_translations[key].nil? && expression_translations[key].length > 0		    				    	
		    		if div.textarea(:name => "translation").present?		    			
		    			div.textarea(:name => "translation").set(expression_translations[key])
		    			div.button(:name => "submit").click
		    		end
	    		end
	    	end
	    end
	end
end
