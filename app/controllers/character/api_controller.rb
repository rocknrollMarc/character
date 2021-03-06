# Author: Alexander Kravets
#         Slate, 2014

class Character::ApiController < ActionController::Base
  include Character::InstanceConcern
  include Character::ModelClassConcern
  include Character::TemplatesConcern
  include Character::JsonObjectConcern
  include Character::AuthConcern
  include Character::ParamsConcern

  before_filter :authenticate_user
  layout :false

  # Actions -----------------------------------------------

  def index
    order_by     = params[:o]
    search_query = params[:q]  || ''
    page         = params[:p]  || 1
    per_page     = params[:pp] || 25

    @objects = model_class.unscoped.all

    # filter
    scopes = params.keys.select { |s| s.starts_with? 'where__' }
    scopes.each do |s|
      field_name = s.gsub('where__', '')

      filters = {}
      filters_list = params[s].split(',')

      if params[s].include? ':'
        params[s].split(',').each do |f|
          filters[ f.split(':').first ] = f.split(':').last
        end

        @objects = @objects.where( field_name => filters )
      else
        @objects = @objects.where( field_name => params[s] )
      end
    end



    # search
    if not search_query.empty?
      @objects = @objects.full_text_search(search_query, match: :all)
    end



    # order
    # format: &order_by=field_name:direction,field_name2:direction,...&
    if order_by
      filters = {}
      order_by.split(',').each do |filter|
        filter_options = filter.split(':')
        filters[filter_options.first] = filter_options.last
        object_fields.append(filter_options.first)
      end

      @objects = @objects.order_by(filters)
    end


    # callback
    if character_instance.before_index
      instance_exec &character_instance.before_index
    end



    # pagination
    @objects = @objects.page(page).per(per_page)



    # result
    item_objects = @objects.map { |o| build_json_object(o) }

    render json: item_objects
  end


  def show
    @object = model_class.find(params[:id])
    render json: @object
  end


  def new
    @object = model_class.new
    @form_action_url = form_action_url(@object)
    render form_template
  end


  def edit
    @object = model_class.find(params[:id])
    @form_action_url = form_action_url(@object)
    render form_template
  end


  def create
    @object = model_class.new( permit_params(form_attributes_namespace) )
    @form_action_url = form_action_url(@object)

    if character_instance.before_save
      instance_exec &character_instance.before_save
    end

    if @object.save
      render json: build_json_object(@object)
    else
      render form_template
    end
  end


  # process backbone model patch save
  def patch
    @object = model_class.find(params[:id])
    @object.assign_attributes(permit_params)

    if character_instance.before_save
      instance_exec &character_instance.before_save
    end

    if @object.save
      render json: :ok
    else
      render json: @object.errors
    end
  end


  # process serialized form, object attributes are in the namespace
  def update
    @object = model_class.find(params[:id])
    @object.assign_attributes( permit_params(form_attributes_namespace) )
    @form_action_url = form_action_url(@object)

    if character_instance.before_save
      instance_exec &character_instance.before_save
    end

    if @object.save
      render json: build_json_object(@object)
    else
      render form_template
    end
  end


  def destroy
    @object = model_class.find(params[:id])
    @object.destroy
    render json: nil, status: 204
  end

  private

  def authenticate_user
    if not auto_login!
      if browserid_authenticated? then login! else render status: :unauthorized, json: { error: "Access denied." } end
    end
  end
end