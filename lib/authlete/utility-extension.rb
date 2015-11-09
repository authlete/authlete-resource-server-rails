module Authlete
  module Utility
    def no_cache_no_store
      headers["Cache-Control"] = "no-store"
      headers["Pragma" ]       = "no-cache"
    end


    def render_text(status, content)
      no_cache_no_store
      render :text => content, :status => status
    end


    def render_html(status, content)
      no_cache_no_store
      render :html => content, :status => status
    end


    def render_json(status, content)
      no_cache_no_store
      render :json => content, :status => status
    end


    def render_json_www_authenticate(status, challenge, content)
      headers["WWW-Authenticate"] = challenge
      render_json(status, content)
    end


    def head_www_authenticate(status, challenge)
      no_cache_no_store
      headers["WWW-Authenticate"] = challenge
      head status
    end


    def redirect(content)
      no_cache_no_store
      redirect_to(content)
    end
  end
end
