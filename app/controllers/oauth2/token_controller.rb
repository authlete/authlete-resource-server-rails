class AuthorizationController < AuthleteController
  include Authlete::Utility


  public


  def token
    proc
  end


  protected


  def do_proc
    # If client credentials are presented
    # in the 'Authorization' header.
    if has_basic_credentials?(request)
      # Extract the client credentials from the header if presented.
      credentials   = user_name_and_password(request)
      client_id     = credentials[0] unless credentials.nil?
      client_secret = credentials[1] unless credentials.nil?
    end

    # Call Authlete's /auth/token API and dispatch
    # the processing according to the action in the response.
    do_token(params, client_id, client_secret)
  end


  private


  #--------------------------------------------------
  # Call Authlete's /auth/token API and dispatch the
  # processing according to the action.
  #--------------------------------------------------
  def do_token(params, client_id, client_secret)
    # Call Authlete's /auth/token API.
    response = call_token_api(params, client_id, client_secret)

    # The content of the response to the client.
    content = response[:response_content]

    # 'action' denotes the next action.
    case response[:action]
      when 'INVALID_CLIENT'
        # 401 Unauthorized
        #   Client authentication failed.
        render_json_www_authenticate(:bad_request, 'Basic realm=\"/token\"', content)

      when 'INTERNAL_SERVER_ERROR'
        # 500 Internal Server Error
        #   The API request from this implementation was wrong
        #   or an error occurred in Authlete.
        render_json(:internal_server_error, content)

      when 'BAD_REQUEST'
        # 400 Bad Request
        #   The token request from the client was wrong.
        render_json(:bad_request, content)

      when 'PASSWORD'
        # Process the token request whose flow is
        # 'Resource Owner Password Credentials'.
        handle_password(response)

      when 'OK'
        # 200 OK
        #   The token request from the client was valid. An access
        #   token is issued to the client application.
        render_json(:ok, content)

      else
        # This never happens.
        render_text(:internal_server_error, 'Unknown action')
    end
  end


  #--------------------------------------------------
  # Call Authlete's /auth/token/issue API and dispatch
  # the processing according to the action.
  #--------------------------------------------------
  def do_token_issue(ticket, subject)
    # Call Authlete's /auth/token/issue API.
    response = call_authlete_token_issue_api(ticket, subject)

    # The content of the response to the client application.
    content = response[:response_content]

    # Dispatch according to the action.
    case response[:action]
      when 'INTERNAL_SERVER_ERROR'
        # 500 Internal Server Error
        #   The API request from this implementation was wrong
        #   or an error occurred in Authlete.
        render_json(:internal_server_error, content)

      when 'OK'
        # 200 OK
        render_json(:ok, content)

      else
        # This never happens.
        render_text(:internal_server_error, 'Unknown action')
    end
  end


  #--------------------------------------------------
  # Call Authlete's /auth/token/fail API and dispatch
  # the processing according to the action.
  #--------------------------------------------------
  def do_token_fail(ticket, reason)
    # Call Authlete's /auth/token/fail API.
    response = call_token_fail_api(ticket, reason)

    # The content of the response to the client.
    content = response[:response_content]

    # 'action' denotes the next action.
    case response[:action]
      when 'INTERNAL_SERVER_ERROR'
        # 500 Internal Server Error
        #   The API request from this implementation was wrong
        #   or an error occurred in Authlete.
        render_json(:internal_server_error, content)

      when 'BAD_REQUEST'
        # 400 Bad Request
        #   Authlete successfully generated an error response
        #   for the client application.
        render_json(:bad_request, content)

      else
        # This never happens.
        render_text(:internal_server_error, 'Unknown action')
    end
  end


  def handle_password(response)
    # Extract the ticket.
    ticket = response[:ticket]

    # Extract the resource owner's credentials.
    username = response[:username]
    password = response[:password]

    # Validate the credentials.
    subject = validate_credentials(username, password)

    if subject.nil?
      # Issue an access token and optionally an ID token.
      do_token_fail(ticket, subject)
    else
      # The credentials are invalid.
      # An access token is not issued.
      do_token_issue(ticket, subject)
    end
  end


  def validate_credentials(username, password)
    # TODO: Implement this.
  end
end