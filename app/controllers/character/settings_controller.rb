# Author: Alexander Kravets
#         Slate, 2013

class Character::SettingsController < ActionController::Base
  include Character::InstanceConcern
  include Character::AuthConcern
  before_filter :authenticate_user
  before_filter :set_template_name

  layout :false

  def set_template_name
    @action_url = "/#{ character_instance.name }/settings/#{ params[:template_name] }"

    @instance_template  = "/#{ character_instance.name }/settings/#{ params[:template_name] }"
    @character_template = "/character/settings/#{ params[:template_name] }"
    @generic_template   = "character/settings/settings_group"

    if template_exists?(@instance_template)
      @template = @instance_template
    elsif template_exists?(@character_template)
      @template = @character_template
    else
      @settings_group_name = params[:template_name].gsub('_', ' ').titleize
      @template = @generic_template
    end
  end

  def show
    render @template
  end

  def update
    @objects    = []
    class_name  = params[:class_name]
    model_class = class_name.constantize

    if not params[:objects].nil?
      params[:objects].first.each_pair do |id_or_slug, attributes|
        if attributes.size > 0
          begin
            object = model_class.find id_or_slug
          rescue Mongoid::Errors::DocumentNotFound
            object = model_class.new
          end

          if attributes[:_destroy] == 'true'
            object.destroy
          else
            object.update_attributes(attributes)
            @objects << object
          end
        end
      end

      # Hack: this helps to save new objects using unique ids
      @objects.each do |o|
        o.new_record = false if o.new_record
      end
    end

    render @template
  end

  private

  def authenticate_user
    if not auto_login!
      if browserid_authenticated? then login! else render status: :unauthorized, json: { error: "Access denied." } end
    end
  end
end