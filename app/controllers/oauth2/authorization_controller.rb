class AuthorizationController < AuthleteController
  include Authlete::Utility


  public


  def authorization
    proc
  end


  protected


  def do_proc
    # Call Authlete's /auth/authorization API and dispatch
    # the processing according to the action in the response.
    do_authorization
  end


  private


  #--------------------------------------------------
  # Call Authlete's /auth/authorization API and
  # dispatch the processing according to the action.
  #--------------------------------------------------
  def do_authorization
    # Call Authlete's /auth/authorization API.
    response = call_authorization_api()

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
        #   The authorization request was invalid.
        render_json(:bad_request, content)

      when 'LOCATION'
        # 302 Found
        #   The authorization request was invalid and the error
        #   is reported to the redirect URI using Location header.
        redirect(content)

      when 'FORM'
        # 200 OK
        #   The authorization request was invalid and the error
        #   is reported to the redirect URI using HTML Form Post.
        render_html(:ok, content)

      when 'NO_INTERACTION'
        # Process the authorization request w/o user interaction.
        handle_no_interaction(response)

      when 'INTERACTION'
        # Process the authorization request with user interaction.
        handle_interaction(response)

      else
        # This never happens.
        render_text(:internal_server_error, 'Unknown action')
    end
  end


  def handle_no_interaction(response)
    # Extract the ticket.
    ticket = response[:ticket]

    # This implementation does not support 'prompt=none'.
    # So, handle_no_interaction always fails.
    do_authorization_fail(ticket, 'UNKNOWN')
  end


  def handle_interaction(response)
    # Put the response from the /auth/authorization API into
    # the session because it is needed later at
    # '/authorization/submit'.
    session[:res] = response

    # Show the authorization page.
    render 'authorization_page'
  end
end