class BaseResourceController < ApplicationController
  include Authlete::Utility


  protected


  #--------------------------------------------------
  # Extract an access token (RFC 6750).
  #--------------------------------------------------
  def extract_access_token(request)
    header = request.env["HTTP_AUTHORIZATION"]

    if /^Bearer[ ]+(.+)/i =~ header
      return $1
    end

    request["access_token"]
  end


  #--------------------------------------------------
  # Introspect the given access token by calling
  # Authlte's /auth/introspection API.
  #
  # When access token is valid, a response from the API
  # is returned.
  # Otherwise, a right error response is given back to
  # the end user and nil is returned to the caller of
  # this method.
  #
  # @param
  # scopes - Array
  #   The required scopes.
  # subject - String
  #   The name of a subject (user) that is supposed to be
  #   associated with the access token.
  #
  # @return
  # On Success, a response from the API.
  # On Failure, nil.
  #--------------------------------------------------
  def introspect_access_token(scopes, subject)
    # Extract an access token from the request.
    access_token = extract_access_token(request)

    # Introspect the access token by /auth/introspection API.
    do_introspect(access_token, scopes, subject)
  end


  private


  def do_introspect_access_token(access_token, scopes, subject)
    # Call Authlete's /auth/introspection API.
    res = call_introspection_api(access_token, scopes, subject)

    # The content of the response to the client.
    content = res["responseContent"]

    # "action" denotes the next action.
    case res["action"]
      when "INTERNAL_SERVER_ERROR"
        # 500 Internal Server Error
        #   The API request from this implementation was wrong
        #   or an error occurred in Authlete.
        head_www_authenticate(:internal_server_error, content)

      when "BAD_REQUEST"
        # 400 Bad Request
        #   The request from the client application does not
        #   contain an access token.
        head_www_authenticate(:bad_request, content)

      when "UNAUTHORIZED"
        # 401 Unauthorized
        #   The presented access token does not exist or has expired.
        head_www_authenticate(:unauthorized, content)

      when "FORBIDDEN"
        # 403 Forbidden
        #   The access token does not cover the required scopes
        #   or the subject associated with the access token is
        #   different.
        head_www_authenticate(:forbidden, content)

      when "OK"
        # The access token is valid (= exists and has not expired).
        return res

      else
        # This never happens.
        render_text(:internal_server_error, "Unknown action")
    end

    # The access token is invalid.
    nil
  end
end