class Admin::Settings::GeneralController < AdminController

	# This controller is used for the settings page. This simply relates to all of the settings that are set in the database

	before_filter :authorize_admin_access

	def create
		redirect = params[:redirect]

		# To do update this table we loop through the fields and update the key with the value. 
		# In order to do this we need to remove any unnecessary keys from the params hash
		remove_unwanted_keys

		# loop through the param fields and update the key with the value
		params.each do |key, value|
			set = Setting.where("setting_name = '#{key}'").update_all('setting' => value)
		end

		redirect_url = "admin_settings_#{redirect}_index_path"

		respond_to do |format|
			format.html { redirect_to send(redirect_url), notice:  "Settings were updated" }
		end
	end

	private


	# removes any unnecessary param field ready for the loop in the create function 

	def remove_unwanted_keys
		params.delete :utf8
		params.delete :authenticity_token
		params.delete :commit
		params.delete :redirect
	end

	private 
	

	# Strong parameters

	def settings_params
		params.permit(:setting_name, :setting)
	end

end