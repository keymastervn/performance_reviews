# frozen_string_literal: true

# READ THIS FOR AUTHENTICATION
# https://developer.atlassian.com/cloud/confluence/basic-auth-for-rest-apis/#supplying-basic-auth-headers
# https://id.atlassian.com/manage-profile/security/api-tokens

# https://developer.atlassian.com/server/confluence/advanced-searching-using-cql/#how-to-perform-an-advanced-search

require 'dotenv'
Dotenv.load

require 'net/http'
require 'json'

class ConfluencePerformanceReview
  def initialize
    @total_doc = 0
    @total_reaction = 0
    @significant_doc = {
      like: 0,
      name: nil
    }
  end

  def call
    response = get_data_from_confluence
    results = JSON.parse(response.body, symbolize_names: true)

    collect_metrics(results)
    display_performance
  end

  private

  def get_data_from_confluence
    params = {
      cql: "(type=page and creator=currentUser() and created >= #{date(ENV['SESSION_START'])} and created <= #{date(ENV['SESSION_END'])})",
      expand: 'etadata.properties,metadata.likes,history',
      limit: 1000 # guess you can't create more than 1000 docs a year hah?
    }
    # The approach below is using content API + CQL for getting the page
    # https://developer.atlassian.com/cloud/confluence/rest/api-group-content/#api-wiki-rest-api-content-search-get
    url = "https://#{ENV['CONFLUENCE_DOMAIN']}/wiki/rest/api/content/search"
    uri = URI(url)
    uri.query = URI.encode_www_form(params)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)

    request.basic_auth ENV['CONFLUENCE_USER'], ENV['CONFLUENCE_API_TOKEN']
    request.content_type = 'application/json'

    # https://developer.atlassian.com/cloud/confluence/rest/intro/#using:~:text=X%2DAtlassian%2DToken%3A%20no%2Dcheck
    request['X-Atlassian-Token'] = 'no-check'

    http.request(request)
  end

  def date(str_8601 = '2021-08-01T00:00:01')
    str_8601.split('T').first
  end

  def collect_metrics(result = {})
    # Be noted that it is hardly to tell if a page is in high quality or not,
    # we could not evaluate your writings' impact, so objectively getting reactions is the strategy

    # if you practice good tag/label then it is possible to categorize by document types
    # eg. design/design proposal/design decision/guidelines/inception/management docs
    # BUT I HAVEN'T DONE IT REGRETTEDLY
    @total_doc = result[:results].size

    result[:results].each do |page|
      likes_count = page[:metadata][:likes][:count]

      @total_reaction += likes_count

      if likes_count > @significant_doc[:like]
        @significant_doc[:like] = likes_count
        @significant_doc[:name] = page[:title]
      end
    end
  end

  def display_performance
    puts "~~~~~~~~~~"
    puts "Hello #{ENV['GITHUB_USERNAME']}"
    puts "From #{ENV['SESSION_START']} to #{ENV['SESSION_END']}"
    puts "You've made #{@total_doc} confluence pages with total #{@total_reaction} likes"
    puts "> The most liked page is #{@significant_doc[:name]} with #{@significant_doc[:like]} likes"
    puts "Keep it up, write more proposals or knowledge pages 📝✍️"
    puts "~~~~~~~~~~"
  end
end

ConfluencePerformanceReview.new.call
