class AuthorizationController < ApplicationController


  public


  def authorization
    begin
      do_authorization
    rescue Exception => e

    end
  end

  def authorization_submit

  end


  private


  def token

  end


  def handle_password(response)
    # This implementation does not support "Resource Owner
    # Password Credentials". So, handle_password always fails.
    return do_token_fail(response["ticket"], "UNKNOWN")
  end


  #--------------------------------------------------
  # Call Authlete's /auth/authorization/fail API and
  # dispatch the processing according to the action.
  #--------------------------------------------------
  def do_token
    # Call Authlete's /auth/authorization/fail API.
    response = call_authorization_fail_api(ticket, reason)

    # The content of the response to the client.
    content = response["responseContent"]

    # "action" denotes the next action.
    case response["action"]
      when "INTERNAL_SERVER_ERROR"
        # 500 Internal Server Error
        #   The API request from this implementation was wrong
        #   or an error occurred in Authlete.
        render :json => content, :status => 500

      when "BAD_REQUEST"
        # 400 Bad Request
        #   The ticket is no longer valid (deleted or expired)
        #   and the reason of the invalidity was probably due
        #   to the end-user's too-delayed response to the
        #   authorization UI.
        render :json => content, :status => 400

      when "LOCATION"
        # 302 Found
        #   The authorization request was invalid and the error
        #   is reported to the redirect URI using Location header.
        return redirect_to(content)

      when "FORM"
        # 200 OK
        #   The authorization request was invalid and the error
        #   is reported to the redirect URI using HTML Form Post.
        render :html => content, :status => 200

      else
        # This never happens.
        render :text => "Unknown action", :status => 500
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
    content = response["responseContent"]

    # "action" denotes the next action.
    case response["action"]
      when "INTERNAL_SERVER_ERROR"
        # 500 Internal Server Error
        #   The API request from this implementation was wrong
        #   or an error occurred in Authlete.
        return WebResponse.new(500, content).json.to_response

      when "BAD_REQUEST"
        # 400 Bad Request
        #   Authlete successfully generated an error response
        #   for the client application.
        return WebResponse.new(400, content).json.to_response

      else
        # This never happens.
        return WebResponse.new(500, "Unknown action").plain.to_response
    end
  end


  #-------------------------------------------
  # Call Authlete APIs.
  #-------------------------------------------
  def call_authorization_api
  end

  def call_authorization_fail_api
  end
end