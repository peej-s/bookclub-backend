# The driver. Defines the webserver and its endpoints.

require "./auth/auth.rb"
require "./core/resources.rb"
require "./core/volumes.rb"
require "./core/errors.rb"

require "json"
require "sinatra"
require "sinatra/cross_origin"
require "sinatra/namespace"

class Bookclub < Sinatra::Base
  # CORS
  configure do
    enable :cross_origin
    set :protection, except: %i[json_csrf]
  end

  before do
    response.headers["Access-Control-Allow-Origin"] = "*"
  end

  options "*" do
    response.headers["Allow"] = "GET, PUT, POST, DELETE, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token"
    response.headers["Access-Control-Allow-Origin"] = "*"
    200
  end

  # Webserver
  register Sinatra::Namespace
  namespace "/api/v1" do
    before { content_type :json }

    get "/volumes" do
      q = params[:q]
      get_volumes_result("/volumes", q)
    end

    get "/volumes/:volume_id" do |volume_id|
      get_volumes_result("/volumes/" + volume_id)
    end

    post "/register" do
      data = JSON.parse(request.body.read)
      username = data["username"]
      pw = data["password"]
      email = data["email"]
      begin
        register_user(username, pw, email)
      rescue AuthError => e
        halt e.status_code, e.msg
      end
    end

    post "/login" do
      data = JSON.parse(request.body.read)
      username = data["username"]
      pw = data["password"]
      begin
        verify_user(username, pw)
      rescue AuthError => e
        halt e.status_code, e.msg
      end
    end

    post "/deactivate" do
      data = JSON.parse(request.body.read)
      access_token = data["access_token"]
      begin
        deactivate_token(access_token)
      rescue AuthError => e
        halt e.status_code, e.msg
      end
      "Successfully deleted token"
    end

    get "/:user_id/protected_endpoint" do |user_id|
      access_token = request.env["HTTP_AUTHORIZATION"]
      if !access_token
        halt 400, "Missing Authorization header in request to protected endpoint"
      end

      access_token = access_token.sub("Bearer ", "")
      begin
        verify_token(user_id, access_token)
      rescue AuthError => e
        halt e.status_code, e.msg
      end
      "Successfully accessed data using correct credentials"
    end
  end
end
