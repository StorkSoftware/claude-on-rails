# Enforces a same-origin Content Security Policy in every environment and
# keeps Active Storage in proxy mode so uploads are served from our origin.
after_bundle do
  create_file "config/initializers/content_security_policy.rb", force: true do
    <<~RUBY
      # Be sure to restart your server when you modify this file.
      #
      # Everything is same-origin; see "Content Security Policy" in CLAUDE.md.
      # https://guides.rubyonrails.org/security.html#content-security-policy-header

      Rails.application.configure do
        config.content_security_policy do |policy|
          policy.default_src     :self
          policy.base_uri        :self
          policy.connect_src     :self
          policy.font_src        :self
          policy.form_action     :self
          policy.frame_ancestors :self
          policy.frame_src       :self
          policy.img_src         :self
          policy.manifest_src    :self
          policy.media_src       :self
          policy.object_src      :none
          policy.worker_src      :self
          # 'strict-dynamic' ignores the 'self' allowlist: every <script> needs the
          # nonce, and scripts it loads (the importmap's modules) are trusted.
          policy.script_src      :self, :strict_dynamic
          # Inline styles stay allowed, so style-src must never get a nonce: a nonce
          # makes the browser ignore 'unsafe-inline'.
          policy.style_src       :self, :unsafe_inline
        end

        # One nonce per session, so it stays valid across Turbo navigations. Not
        # session.id: it is blank until the session is first written, and an
        # empty nonce blocks every script on a visitor's first page.
        config.content_security_policy_nonce_generator = ->(request) { request.session[:csp_nonce] ||= SecureRandom.base64(16) }
        config.content_security_policy_nonce_directives = %w[script-src]
        config.content_security_policy_nonce_auto = true
      end
    RUBY
  end

  # Redirect mode would send blobs to the storage service's origin, which
  # img-src 'self' blocks.
  environment "config.active_storage.resolve_model_to_route = :rails_storage_proxy"

  commit "Enforce a same-origin Content Security Policy"
end
