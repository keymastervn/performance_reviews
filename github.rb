# frozen_string_literal: true

require 'dotenv'
require 'graphql/client'
require 'graphql/client/http'
require 'byebug'

Dotenv.load

class GithubPerformanceReview
  HTTP = ::GraphQL::Client::HTTP.new('https://api.github.com/graphql') do
    def headers(_context)
      token = 'Basic ' + Base64.strict_encode64("#{ENV['GITHUB_USERNAME']}:#{ENV['GITHUB_ACCESS_TOKEN']}")
      {
        'Authorization' => token,
        'Accept' => 'application/vnd.github.vixen-preview+json'
      }
    end
  end

  Schema = GraphQL::Client.load_schema(HTTP)
  # However, it's smart to dump this to a JSON file and load from disk
  #
  # Run it from a script or rake task
  #   GraphQL::Client.dump_schema(SWAPI::HTTP, "path/to/schema.json")
  #
  # Schema = GraphQL::Client.load_schema("path/to/schema.json")

  Client = ::GraphQL::Client.new(schema: Schema, execute: HTTP)

  # PullRequestQuery = Client.parse <<~GRAPHQL
  #   query ($gh_user: String!) {
  #     user(login: $gh_user) {
  #       issueComments(last: 100) {
  #         nodes {
  #           repository {
  #             name
  #             nameWithOwner
  #             owner {
  #               id
  #               login
  #               url
  #             }
  #           }
  #           issue {
  #             number
  #           }
  #           pullRequest {
  #             number
  #             author {
  #               login
  #             }
  #           }
  #           body
  #           createdAt
  #         }
  #       }
  #     }
  #   }
  #   variables {
  #     "gh_user": "keymastervn",
  #     "gh_owner": "Thinkei"
  #   }
  # GRAPHQL

  # Alright, you can play here https://docs.github.com/en/graphql/overview/explorer
  OverallQuery = Client.parse <<~GRAPHQL
    query ($gh_user: String!, $gh_org_id: ID!, $from: DateTime!, $to: DateTime!, $after_cursor: String) {
      user(login: $gh_user) {
        contributionsCollection(from: $from, to: $to, organizationID: $gh_org_id) {
          pullRequestReviewContributions(first: 100, orderBy: { direction: ASC }, after: $after_cursor) {
            edges {
              cursor
              node {
                pullRequestReview {
                  body
                  createdAt
                  url
                  comments(first: 100) {
                    nodes {
                      body
                      url
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  GRAPHQL

  def initialize
    @total_pr = 0
    @total_comment = 0

    # I perceive it as good code review, it should be an external reference or wrapped within ```suggestion``` block
    @comment_with_suggestion = 0

    # This should be intuitive and straightforward rather than ping pong
    @comment_gt_200_char = 0

    # This is perceived as negative: the longer a comment is, a harsh feeling and not focusing on the detail it is
    @comment_gt_500_char = 0
  end

  def call
    # Persist it somewhere first so the values are not cleanup in each loop
    result = nil
    loop do
      result = Client.query(
        OverallQuery,
        variables: variables(get_last_cursor(result))
      )

      extract_results(result)

      break if get_last_cursor(result).nil?
    end

    display_performance
  end

  private

  def variables(cursor = nil)
    {
      'gh_user' => ENV['GITHUB_USERNAME'],
      'gh_owner' => ENV['GITHUB_OWNER'],
      'gh_org_id' => ENV['GITHUB_OWNER_ID'],
      'from' => ENV['SESSION_START'],
      'to' => ENV['SESSION_END'],
      'after_cursor' => cursor
    }
  end

  def get_last_cursor(result)
    result.data.user.contributions_collection.pull_request_review_contributions.edges&.last&.cursor if result
  end

  def extract_results(result)
    result.data.user.contributions_collection.pull_request_review_contributions.edges.each do |edge|
      @total_pr += 1

      @total_comment += 1 unless edge.node.pull_request_review.body.empty?

      edge.node.pull_request_review.comments.nodes.each do |comment|
        @total_comment += 1
        body = comment.body

        @comment_with_suggestion += 1 if body.include?('https://') ||
          body.include?('http://') ||
          body.include?('```suggestion')

        @comment_gt_200_char += 1 if body.length > 200
        @comment_gt_500_char += 1 if body.length > 500
      end
    end
  end

  def display_performance
    puts "~~~~~~~~~~"
    puts "Hello #{ENV['GITHUB_USERNAME']}"
    puts "From #{ENV['SESSION_START']} to #{ENV['SESSION_END']}"
    puts "You've made #{@total_pr} PR reviews in #{ENV['GITHUB_OWNER']} with #{@total_comment} comments"
    puts "There are #{@comment_with_suggestion} comments in good quality, #{@comment_gt_200_char} are short-form and #{@comment_gt_500_char} are long-form"
    puts "Keep it up, review code better 💪💪💪"
    puts "~~~~~~~~~~"
  end
end

pr = GithubPerformanceReview.new
pr.call
