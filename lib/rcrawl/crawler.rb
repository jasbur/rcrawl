module Rcrawl

	class Crawler
		
		attr_accessor :links_to_visit, :site, :user_agent
		attr_reader :visited_links, :external_links, :raw_html, :rules, :sites,
						:errors, :meta
		# Initializes various variables when a new Crawler object is instantiated
		def initialize(site)
			puts "Rcrawl Version #{VERSION} initializing..."
			@links_to_visit = Array.new
			@visited_links = Array.new
			@external_links = Array.new
			@raw_html = Hash.new
			@rules = RobotRules.new('Rcrawl')
			@user_agent = "Rcrawl/#{VERSION} (http://rubyforge.org/projects/rcrawl/)"
			@sites = Hash.new
			@errors = Hash.new
			@meta = Hash.new
			@site = URI.parse(site) || raise("You didn't give me a site to crawl")
			@links_to_visit << site
			puts "Ready to crawl #{site}"
		end

		# Coordinates the whole crawling process
		def crawl
			until @links_to_visit.empty? do
				begin
					# Get link
					url_server
					next unless robot_safe? @url
					if @url.include? '#'
						print "... Anchor link found, skipping..."
						next
					end
					# Parse robots.txt, then download document if robot_safe
					fetch_http(@url)
					# Store raw HTML in variable to read/reread as needed
					# Then call any processing modules you need for the current document
					ris(@document)
				rescue
					puts ""
					puts "I died on #{@url}"
					$stderr.puts $!
					@errors[@url] = $!
					next
				ensure
					# Stuff you want to make sure gets printed out
					puts " done!"
				end
			end

			puts "Visited #{@visited_links.size} links."
		end

		# Authoritative list of URLs to be processed by Rcrawl
		def url_server
			unless @links_to_visit.empty?
				@url = @links_to_visit.pop
			end
		end

		# Download the document
		def fetch_http(url)
			# Make sure robots.txt has been parsed for this site first,
			# if not, parse robots.txt then grab document.
			uri = URI.parse(url)
			print "Visiting: #{url}"
			@document = uri.read("User-Agent" => @user_agent, "Referer" => url)
			@visited_links << url
		end

		# Rewind Input Stream, for storing and reading of raw HTML
		def ris(document)
			print "."
			# Store raw HTML into local variable
			# Based on MIME type, invoke the proper processing modules
			case document.content_type
				when "text/html"
					link_extractor(document)
					process_html(document)
					page_meta(document)
				else
					print "... not HTML, skipping..."
			end
		end

		# HTML processing module for extracting links
		def link_extractor(document)
			print "."
			# Parse all links from HTML into an array
			# Set up the scrAPI (http://labnotes.org)
			links = Scraper.define do
				array :urls
				process "a[href]", :urls => "@href"
				result :urls
			end
			
			urls = links.scrape(document)
			
			urls.each { |url|
			uri = URI.parse(url)
			
			# Derelativeize links if necessary
			if uri.relative?
				url = @site.merge(url).to_s
				uri = URI.parse(url)
			end
			
			# Check domain, if in same domain, keep link, else trash it
			if uri.host != @site.host
				@external_links << url
				@external_links.uniq!
				next
			end

			# Find out if we've seen this link already
			if (@visited_links.include? url) || (@links_to_visit.include? url)
				next
			end

			@links_to_visit << url
		}
		end
			
		# HTML processing module for raw HTML storage
		def process_html(document)
			
			# Add link and raw HTML to a hash as key/value
			# for later storage in database
			unless @raw_html.has_value?(document)
		  		print "."
		  		@raw_html[@document.base_uri.to_s] = document
			end
				
		end
		
		def page_meta(document)
			@meta[@url] = document.meta
		end
		
		# robots.txt parsing
		def robot_safe?(url)
			uri = URI.parse(url)
			location = "#{uri.host}:#{uri.port}"

			return true unless %w{http https}.include?(uri.scheme)

			unless @sites.include? location
				@sites[location] = true

				robot_url = "http://#{location}/robots.txt"
				begin
					robot_file = open(robot_url) { |page| page.read }
				rescue
					return true
				end
				@rules.parse(robot_url, robot_file)
			end

			@rules.allowed? url
		end

	end # class Crawler
	
end # module Rcrawl
