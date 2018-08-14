# Gleam test

require 'twitter'
require 'selenium-webdriver'
require 'colorize'
require 'io/console'
require_relative 'gleam_handler'

def initialise
	set_up_client
	link = ARGV[0]
	go_to_external_link(link)
end

def set_up_client

	$client = Twitter::REST::Client.new do |config|
	  config.consumer_key        = "5bj9IHxE0ZsdtHZGDCSMuCQwo"
	  config.consumer_secret     = "fYduoWLjRoxmoky8gxMbuE9gm6GmwdIzDNYM7IqOb6f08LPwtm"
	  config.access_token        = "912337569081364480-tVb4lFcgXcJmkPw7TnEXsQTSPuXL1kb"
	  config.access_token_secret = "opSFB9hkrT4zi29QArCJNmVLnGsilIQjPaRwLjoVOROF8"
	end

	# Set the chromedriver path
	Selenium::WebDriver::Chrome.driver_path = "/Users/stevegoldsworthy/Ruby/chromedriver"

end

def go_to_external_link(link)

	options = Selenium::WebDriver::Chrome::Options.new
	options.add_argument('--ignore-certificate-errors')
	options.add_argument('--disable-popup-blocking')
	options.add_argument('--disable-translate')

	client = Selenium::WebDriver::Remote::Http::Default.new
	client.open_timeout = 10

	driver = Selenium::WebDriver.for :chrome, http_client: client
	
	begin
		driver.get(link)

		puts driver.current_url

		if driver.current_url.include? "gleam"
			puts "This is a GLEAM giveaway".colorize(:yellow)
			
			gleam = GleamHandler.new(driver)

		end
	rescue Net::ReadTimeout
		puts "Error - link timed out".colorize(:red)
	end

	# driver.quit
end

initialise