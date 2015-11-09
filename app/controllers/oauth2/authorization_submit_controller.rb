class AuthorizationSubmitController < AuthleteController
  include Authlete::Utility


  public


  def authorization_submit
    process
  end


  protected


  def do_proc
    # Extract the authorization response from the session.
    response = session[:res]

    # If the end-user authorized the client application.
    if params['authorized'] === 'true'
      # Authenticate the end-user and then
      # issue an authorizatino code to the client application.
      authenticate_and_issue_code(response)
    else
      # Notify the client application that the end-user denied
      # the authorization request.
      deny_authorization_request(response)
    end
  end


  private


  def authenticate_and_issue_code(response)
    begin
      do_issue_code_after_authentication(response)
    # TODO: Consider a kind of exception thrown here.
    rescue => e
      # Go back to the authorization page.
      go_back_to_authorization_page(e)
    end
  end


  def do_issue_code_after_authentication(response)
    # Authenticate the end-user.
    auth_result = authenticate()

    # Check the required subject.
    check_required_subject(response, auth_result)

    # Issue an authorization code to the client application.
    issue_code(response, auth_result)
  end


  def go_back_to_authorization_page(exception)
    # Set the error message to show on the authorization page.
    @error_messasge = exception.to_s

    # Show the authorization page again.
    render 'authorization_page'
  end


  def authenticate
    # Authenticate the end-user.
    auth_result = authentication_callback(params['username'], params['password'])

    # If the authentication fails, go back.
    if auth_result.authenticated === false
      # Raise an error.
      error('User authentication failed.')
    end

    return auth_result
  end


  def issue_code(response, subject)
    # Extract the ticket.
    ticket = response[:ticket]

    # The time when the end-user was authenticated.
    auth_time = Time.now.to_i / 1000

    # Issue an authorization code to the client application
    # by delegating the process to Authlete.
    do_authorization_issue(ticket, subject, auth_time)
  end


  def check_required_subject(response, auth_result)
    required_subject = response[:subject]

    if required_subject.nil?
      # OK.
      return
    end

    if required_subject === auth_result[:subject]
      # OK.
      return
    end

    # Raise an error.
    error("Must Log in as #{required_subject}.")
  end


  def deny_authorization_request(response)
    # Extract the ticket.
    ticket = response[:ticket]

    # Notify the client application that the end-user denied
    # the authorization request by delegating the process to
    # Authlete.
    do_authorization_fail(ticket, 'DENIED')
  end


  def error(message)
    # TODO: Consider a kind of exception thrown here.
    logger.error(message)
    raise error_message
  end


  #--------------------------------------------------
  # Call Authlete's /auth/authorization/issue API and
  # dispatch the processing according to the action.
  #--------------------------------------------------
  def do_authorization_issue(ticket, subject, auth_time)
    # Call Authlete's /auth/authorization/issue API.
    response = call_authorization_issue_api(ticket, subject, auth_time)

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
        #   The ticket is no longer valid (deleted or expired)
        #   and the reason of the invalidity was probably due
        #   to the end-user's too-delayed response to the
        #   authorization UI.
        render_json(:bad_request, content)

      when 'LOCATION'
        # 302 Found
        #   Triggering redirection with either (1) an authorization
        #   code, an ID token and/or an access token (on success)
        #   or (2) an error code (on failure).
        redirect(content)

      when 'FORM'
        # 200 OK
        #   Triggering redirection with either (1) an authorization
        #   code, an ID token and/or an access token (on success)
        #   or (2) an error code (on failure).
        render_html(:ok, content)

      else
        # This never happens.
        render_text(:internal_server_error, 'Unknown action')
    end
  end
end