class AuthleteController < ApplicationController


  public


  # Execute the process.
  # This method is expected to be used in the sub classes.
  def proc(on_authlete_exception = :on_authlete_exception,
           on_general_exception  = :on_general_exception)
    begin
      # Execute the process.
      return do_proc
    rescue Authlete::Exception => e
      # Handle Authlete::Exception.
      handle_exception(e, on_authlete_exception)
    rescue Exception => e
      # Handle general exception.
      handle_exception(e, on_general_exception)
    end
  end


  protected


  # Execute the main process.
  # Note that this method is expected to be overridden
  # in the sub classes.
  def do_proc
  end


  def handle_exception(exception, on_exception)
  end


  #--------------------------------------------------
  # Call Authlete's /auth/authorization/fail API and
  # dispatch the processing according to the action.
  #--------------------------------------------------
  def do_authorization_fail(ticket, reason)
    # Call Authlete's /auth/authorization/fail API.
    response = call_authorization_fail_api(ticket, reason)

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
        #   The authorization request was invalid and the error
        #   is reported to the redirect URI using Location header.
        redirect(content)

      when 'FORM'
        # 200 OK
        #   The authorization request was invalid and the error
        #   is reported to the redirect URI using HTML Form Post.
        render_html(:ok, content)

      else
        # This never happens.
        render_text(:internal_server_error, 'Unknown action')
    end
  end


  #-------------------------------------------
  # Call Authlete APIs.
  #-------------------------------------------
  def call_authorization_api
  end


  def call_authorization_issue_api(ticket, subject, auth_time)
  end


  def call_authorization_fail_api(ticket, reason)
  end


  def call_token_api(params, client_id, client_secret)
  end

end