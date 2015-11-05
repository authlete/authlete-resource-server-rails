class AuthorizationController < ApplicationController

  public


  def authorization
    begin
      do_authorization
    rescue Exception => e

    end
  end


  def submit

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
        #   The authorization request was invalid.
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

      when "NO_INTERACTION"
        # Process the authorization request w/o user interaction.
        return handle_no_interaction(response)

      when "INTERACTION"
        # Process the authorization request with user interaction.
        return handle_interaction(session, response)

      else
        # This never happens.
        render :text => "Unknown action", :status => 500
    end
  end


  def handle_no_interaction(response)
    # This implementation does not support "prompt=none".
    # So, handle_no_interaction always fails.
    return do_authorization_fail(response["ticket"], "UNKNOWN")
  end


  def handle_interaction(session, response)
    # Put the response from the /auth/authorization API into
    # the session because it is needed later at
    # '/authorization/submit'.
    session[:res] = response

    # Render the UI.
    erb :authorization_ui, :locals => { :res => response }
  end


  #--------------------------------------------------
  # Call Authlete's /auth/introspection API.
  # A response from the API is returned when the
  # access token is valid. Otherwise, a WebException
  # is raised.
  #--------------------------------------------------
  def do_introspection(token, scopes, subject)
    # Call Authlete's /auth/introspection API.
    response = call_introspection_api(token, scopes, subject)

    # The content of the response to the client.
    content = response["responseContent"]

    # "action" denotes the next action.
    case response["action"]
      when "INTERNAL_SERVER_ERROR"
        # 500 Internal Server Error
        #   The API request from this implementation was wrong
        #   or an error occurred in Authlete.
        raise WebResponse.new(500).wwwAuthenticate(content).to_exception

      when "BAD_REQUEST"
        # 400 Bad Request
        #   The request from the client application does not
        #   contain an access token.
        raise WebResponse.new(400).wwwAuthenticate(content).to_exception

      when "UNAUTHORIZED"
        # 401 Unauthorized
        #   The presented access token does not exist or has expired.
        raise WebResponse.new(401).wwwAuthenticate(content).to_exception

      when "FORBIDDEN"
        # 403 Forbidden
        #   The access token does not cover the required scopes
        #   or the subject associated with the access token is
        #   different.
        raise WebResponse.new(403).wwwAuthenticate(content).to_exception

      when "OK"
        # The access token is valid (= exists and has not expired).
        return response

      else
        # This never happens.
        raise WebResponse.new(500, "Unknown action").plain.to_exception
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