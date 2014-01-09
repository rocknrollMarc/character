module AuthHelper
  def auto_login!
    if ( character_instance.development_auto_login and Rails.env.development? ) or Rails.env.test?
      @browserid_email = 'developer@character.org'
      @current_user = character_instance.user_class.new(email: @browserid_email)
      return true
    else
      return false
    end
  end

  def login!
    @current_user = browserid_current_user
  end

  def register_first_user!
    @browserid_email = browserid_email

    if character_instance.user_class.first
      return false
    else
      @current_user = character_instance.user_class.create(email: @browserid_email) if @browserid_email
      return true
    end
  end

  def browserid_config
    @browserid_config ||= begin
      config = Rails.configuration.browserid.clone
      config.user_model       = character_instance.user_model
      config.session_variable = "#{ character_instance.name }_browserid_email"
      config.login.text       = 'Sign-in with Persona'
      config.login.path       = "/#{ character_instance.name }/login"
      config.logout.path      = "/#{ character_instance.name }/logout"
      config
    end
  end
end