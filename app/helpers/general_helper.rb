module GeneralHelper

	# get a value from the theme yaml file by the key 
	# Params:
	# +key+:: YAML key of the value that you want to retrive

	def theme_yaml key = nil 
		if File.exists?("#{Rails.root}/app/views/theme/#{current_theme}/theme.yml")
			theme_yaml = YAML.load(File.read("#{Rails.root}/app/views/theme/#{current_theme}/theme.yml"))
			theme_yaml[key]
		else
			'html.erb'
		end
	end

	# rewrite the theme helper to use the themes function file

	def rewrite_theme_helper

		if File.exists?("#{Rails.root}/app/views/theme/#{current_theme}/theme_helper.rb")
			
			# get the theme helper from the theme folder
		    file = File.open("#{Rails.root}/app/views/theme/#{current_theme}/theme_helper.rb", "rb")
		    contents = file.read

		    # check if the first line starts with the module name or not
		    parts = contents.split(/[\r\n]+/)

		    if parts[0] != 'module ThemeHelper'
		      contents = "module ThemeHelper\n\n" + contents + "\n\nend"
		    end

		    # write the contents to the actual file file
		    File.open("#{Rails.root}/app/helpers/theme_helper.rb", 'w') { |file| file.write(contents) }


		else 
			contents = "module ThemeHelper\n\nend"
			File.open("#{Rails.root}/app/helpers/theme_helper.rb", 'w') { |file| file.write(contents) }
		end

	    load("#{Rails.root}/app/helpers/theme_helper.rb")
	end

	def check_theme_folder
		if !File.exists?("#{Rails.root}/app/views/theme/#{current_theme}/theme.yml")
			render :inline => "There is no theme.yml file included in the theme" and return 
		end
	end

end
