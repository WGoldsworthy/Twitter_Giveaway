# Giveaway BOT
# Author: William Goldsworthy
# 25-09-2017

require 'twitter'
require 'selenium-webdriver'
require 'colorize'
require 'io/console'
require_relative 'gleam_handler'


def initialise
	print_ascii
	puts "Running ... "
	set_up_client
	puts "Client Initialised ..."
	search_giveaway
end

def print_ascii
	puts "
	 _____           _____ _____ _____ 
	|_   _|   ___   | __  |     |_   _|
	  | |    |___|  | __ -|  |  | | |  
	  |_|           |_____|_____| |_|  
                                  "
end

def set_up_client

	$client = Twitter::REST::Client.new do |config|
	  config.consumer_key        = "5bj9IHxE0ZsdtHZGDCSMuCQwo"
	  config.consumer_secret     = "fYduoWLjRoxmoky8gxMbuE9gm6GmwdIzDNYM7IqOb6f08LPwtm"
	  config.access_token        = "912337569081364480-tVb4lFcgXcJmkPw7TnEXsQTSPuXL1kb"
	  config.access_token_secret = "opSFB9hkrT4zi29QArCJNmVLnGsilIQjPaRwLjoVOROF8"
	end

	# Set the chromedriver path
	Selenium::WebDriver::Chrome::Service.driver_path = "./chromedriver"

end


def search_giveaway

	if ARGV[0]
		search_term = ARGV[0]
	else
		search_term = ''
	end

	if ARGV[1]
		numTake = ARGV[1].to_i
	else 
		#TODO: Make this infinte
		numTake = 5
	end

	$client.search("#{search_term} giveaway -filter:retweets -entered exclude:replies", tweet_mode: "extended", result_type: "mixed", include_entities: "true").take(numTake).collect do |tweet|

	  # Retrieve the urls from within the tweet and go to it using selenium
	  # This mainly works when including "gleam" in the search. Currently done in the cmd line ARGVs
	  urls = tweet.urls();
	  urls.each do |url|
	  	puts url.expanded_url
	  	go_to_external_link(url.expanded_url)
	  end

	  # Extended tweet mode gets the correct urls, but doesnt seem to include the text
	  # Need to find another way to get the text for giveaways that are not gleam
	  # Maybe time slice searching gleam giveaways and retweet/follow/like giveaways
	  puts "#{tweet.user.screen_name} : ".colorize(:blue) + "#{tweet.text}"

	  # Check what actions we need to do in order to enter the giveaway
	  actions = check_tweet(tweet.text)
	  puts " "


	  actions.each do |action|
			case action.to_s
			when "0"
				retweet_tweet(tweet)
			when "1"
				follow_user(tweet)
			when "2"
				like_tweet(tweet)
			when "3"
				link = fetch_external_link(tweet.text)
				go_to_external_link(link)
			else
				# list other options and tasks
			end
		end 
	end


	# Alternative search that includes searching for tweets that include RT
	# $client.search("giveaway AND RT -filter:retweets -entered exclude:replies").take(5).collect do |tweet|

	# 	puts "#{tweet.user.screen_name}: #{tweet.text}"

	# 	# Check what actions we need to do in order to enter the giveaway
	# 	actions = check_tweet(tweet.text)
	# 	puts actions.to_s
	# 	puts " "
	# 	# foreach in actions, case statement to method

		
	# end

end


def check_tweet(tweet_text)

	# Actions array contains list of actions required to enter the giveaway
	# 0 - Retweet
	# 1 - Follow user
	# 2 - Like
	# 3 - External Link
	
	actions = []

	tweet_text = tweet_text.downcase

	if tweet_text.include?("rt") || tweet_text.include?("retweet")
		puts "Tweet contains RT - Must Retweet."
		actions.push(0)
	end

	if tweet_text.include? "follow"
		puts "Tweet contains Follow - Must Follow"
		actions.push(1)
	end

	if tweet_text.include? "like"
		puts "Tweet contains Like - Must Like"
		actions.push(2)
	end

	# Check is the tweet contains a link to an external site
	if tweet_text.include? "https://t.co"
		puts "Tweet contains an external link."
		actions.push(3)
	end

	return actions
end

def like_tweet(tweet)
	begin
		$client.favorite(tweet)
	rescue Twitter::Error::Forbidden
		puts "Warning - Already liked this tweet".colorize(:red)
	end
end


def retweet_tweet(tweet)
	begin 
		puts "Retweeting"
		$client.retweet(tweet)
	rescue Twitter::Error::Forbidden
		puts "Warning - Already Retweeted this tweet".colorize(:red)
	end
end


def follow_user(tweet)
	user = tweet.user
	begin
		$client.follow(user)
	rescue Twitter::Error::Forbidden
		puts "Warning - Already Following this user".colorize(:red)
	end
end


def fetch_external_link(tweet_text)

	puts "Finding External Link"
	start_link = tweet_text.index("https://t.co")

	rest = tweet_text[start_link .. -1]

	end_link = rest.index(" ")

	if end_link
		link = rest[0, end_link]
	else
		link = rest
	end
	puts link
	# need to return link in order to go to in selenium
	return link

end

# Use selenium webdriver to go to external links
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

		if driver.current_url.include? "gleam"
			puts "This is a GLEAM giveaway".colorize(:yellow)
			
			gleam = GleamHandler.new(driver)

		end
	rescue Net::ReadTimeout
		puts "Error - link timed out".colorize(:red)
	end
end


initialise