# Gleam.io handler
# Author: William Goldsworthy
# 08.10.2017

# TODO:

require 'selenium-webdriver'

class GleamHandler

	def initialize(driver)
		@driver = driver
		puts "Initialized Gleam Handler"
		list_actions()
	end

	# Methods index is always one larger than its action buttons index.

	def get_original_window_handle
		return @driver.window_handle
	end

	def list_actions
		begin
			original_window = get_original_window_handle

			entry_methods_text = @driver.find_elements(css: '.entry-content .text')
			action_buttons = @driver.find_elements(css: '.entry-content .tally')
			entry_methods = @driver.find_elements(css: '.entry-method')
			twitter_follow_buttons = @driver.find_elements(css: '.twitter-button')

			i = 0
			twitter_button_count = 0

			entry_methods_text.each do |method|
				puts method.text

				if is_twitter_follow(method.text)

					# Custom action to click on the twitter follow
					@driver.action.move_to(entry_methods_text[i]).click().perform

					puts "Clicking Following on Twitter".colorize(:blue)
					sleep( 2 )

					# There are different version that gleam uses. Sometimes pop ups in another window, 
					# Sometimes drop box with follow and connect twitter account buttons.
					# Sometimes new tab of the page to follow, username/pass input top right

					@driver.action.move_to(twitter_follow_buttons[twitter_button_count]).click.perform
					twitter_button_count += 1
					
					sleep( 2 ) 

					# First twitter button click will open the twitter login
					# Second click will open an auth window. Need to not switch to this window
					if twitter_button_count == 1
						handles = @driver.window_handles()
						handles.each do |handle|
							puts handle
							if handle != original_window
								@driver.switch_to.window(handle)
								twitter_log_in(original_window)
							end
						end
						@driver.switch_to.window(original_window)
					elsif twitter_button_count == 2 
						sleep( 2 ) # Wait for Auth window to redirect
					else 
						# Continue. Should be no other windows
					end
				end

				i += 1
			end

			# After going through all the gleam methods close the driver
			@driver.quit
		rescue Selenium::WebDriver::Error::NoSuchElementError
			puts "WARNING - No Entry Content elements".colorize(:yellow)
		end
	end


	def is_twitter_follow(text)

		if text.downcase.include?("follow") && text.downcase.include?("twitter")
			return true
		else
			return false
		end

	end


	def twitter_log_in(original_window)

		puts "Twitter Log In Initiated"

		usernameInput = @driver.find_element(css: '#username_or_email')
		passwordInput = @driver.find_element(css: '#password')
		submitButton = @driver.find_element(css: '.submit.button')

		usernameInput.send_keys "WGoldswork"
		passwordInput.send_keys "29will29"
		submitButton.click()
		sleep( 2 )
		@driver.close()
		@driver.switch_to.window(original_window)
		puts "SELENIUM - Switching back to original window"
		return
	end


end