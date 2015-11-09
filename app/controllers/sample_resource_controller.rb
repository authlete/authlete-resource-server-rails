class SampleResourceController < BaseResourceController
  def get_hello
    # Validate the access token.
    #
    # Note that, if the access token invalid,
    # 'introspect_access_token' gives a right response
    # back to the end user.
    # For example, if the access token is expired,
    # a response whose status is '401 Unauthorized' is
    # presented to the end user.
    introspected = introspect_access_token([ 'hello' ], 'Bob')

    # If the access token is invalid (the returned value is nil).
    return if introspected.nil?

    # If the access token is valid.
    render :json => 'Hello', :status => :ok
  end
end