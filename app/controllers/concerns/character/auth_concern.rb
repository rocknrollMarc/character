module Character::AuthConcern
  extend ActiveSupport::Concern

  included do

    force_ssl if: :ssl_required?

    def ssl_required?
      if Rails.env.production?
        character_instance.force_ssl
      else
       false
      end
    end

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
  end
end