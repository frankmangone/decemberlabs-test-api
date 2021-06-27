class ApplicationController < ActionController::API

  #
  # User authentication methods
  def self.encode_token(payload)
    JWT.encode(payload, ENV['JWT_SECRET_KEY'])
  end

  def auth_header
    # Returns 'Bearer <token>' if present
    request.headers['Authorization']
  end

  def decoded_token
    if auth_header
      # auth_header = 'Bearer <token>'
      token = auth_header.split(' ')[1]
      begin
        JWT.decode(token, ENV['JWT_SECRET_KEY'], true, algorithm: 'HS256')
      rescue JWT::DecodeError
        nil
      end
    end
  end

  def authenticate_user
    if decoded_token
      user_id = decoded_token[0]['user_id']
      @user = User.find_by_id(user_id)
    end
  end
end
