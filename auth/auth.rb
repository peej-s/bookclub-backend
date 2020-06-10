# Auth will take care of authentication

require 'bcrypt' # https://github.com/codahale/bcrypt-ruby 
require './core/repositories.rb'
require 'date'

def verify_input(username, pw)
  error = nil
  if username.nil? || username.empty?
    error = "Missing `username` in request"
  elsif pw.nil? || pw.empty?
    error = "Missing `password` in request"
  end
  error
end

def verify_registration_input(username, pw, email)
  error = verify_input(username, pw)
  if email.nil? || email.empty?
    error = "Missing `email` in request"
  end
  error
end

def register_user(username, pw, email)
  error = verify_registration_input(username, pw, email)
  if error
    return error
  end

  user = get_user_from_username(username)
  if user
    return "User already exists"
  end

  hashed_password = BCrypt::Password.create(pw)
  userdata = {
    username: username,
    hashed_password: hashed_password,
    email: email,
    source: "bookclub",
  }
  user_id = create_user(userdata)
  generate_token(user_id).to_json
end

def verify_user(username, pw)
  error = verify_input(username, pw)
  if error
    return error
  end

  user = get_user_from_username(username)
  if !user
    "User does not exist"
  else
    hashed_password = user["hashed_password"]

    token = "Incorrect password"
    if (BCrypt::Password.new(hashed_password) == pw)
      token = generate_token(user["id"]).to_json
    end
    token
  end
end

def deactivate_token(access_token)
  if access_token.nil? || access_token.empty?
    return "Missing `access_token` in Logout Request"
  end
  modified = delete_token(access_token)
  response = "Could not delete token: No such token found in database"
  if modified > 0
    response = "Successfully deleted token"
  end
  response
end

def verify_token(user_id, access_token)
  error = "Invalid token/user_id combination"
  token = get_token(user_id, access_token)
  if token
    if Time.now < token["expiry"]
      error = nil
    else
      error = "Token expired"
    end
  end
  error
end