OmniAuth.config.on_failure = Proc.new do |env|

  	OauthController.action(:failure).call(env)

end