module Character
  class Namespace
    DEFAULT_NAMESPACE = 'admin'

    attr_accessor :name,
                  :title,
                  :user_model,

                  :permissions_filter,
                  :before_index,
                  :before_save,

                  :javascript_filename,
                  :stylesheet_filename,

                  :logo_image,
                  :login_background_image

    def initialize(name = Namespace::DEFAULT_NAMESPACE)
      @name                   = name.gsub(' ', '-').downcase #.to_url ? where this method is from? need to include in gemspec
      @title                  = 'Character'
      @user_model             = 'Character::User'
      @logo_image             = 'rails.png'
      @login_background_image = 'http://images.nationalgeographic.com/exposure/core_media/ngphoto/image/68263_0_1040x660.jpg'
    end

    def title
      @title || @name.humanize
    end

    def javascript_filename
      @javascript_filename || @name
    end

    def stylesheet_filename
      @stylesheet_filename || @name
    end

    def user_class
      @user_class ||= @user_model.constantize
    end

    def default?
      @name == Namespace::DEFAULT_NAMESPACE
    end
  end
end