module Authlete
  module Utility
    def no_cache_no_store
      headers["Cache-Control"] = "no-store"
      headers["Pragma" ]       = "no-cache"
    end


    def head_www_authenticate(status, content)
      no_cache_no_store
      headers["WWW-Authenticate"] = content
      head status
    end


    def render_text(status, content)
      no_cache_no_store
      render :text => content, :status => status
    end
  end
end
