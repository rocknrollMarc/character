# Author: Alexander Kravets
#         Slate, 2013

class Character::ApiController < Character::BaseController
  include NamespaceHelper
  include ModelClassHelper
  include TemplatesHelper
  include JsonObjectHelper

  # Actions -----------------------------------------------

  # - the index action implements order, search and paging
  # TODO: implement filtering
  def index
    order_by     = params[:order_by]
    search_query = params[:search_query] || ''
    page         = params[:page]         || 1
    per_page     = params[:per_page]     || 200

    @objects = model_class.unscoped.all



    # filter with where
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



    # search option
    #@objects = @objects.full_text_search(search_query) if not search_query.empty?



    # order_by format: &order_by=field_name:direction,field_name2:direction,...&
    if order_by
      filters = {}
      order_by.split(',').each do |filter|
        filter_options = filter.split(':')
        filters[filter_options.first] = filter_options.last
        object_fields_to_include.append(filter_options.first)
      end

      @objects = @objects.order_by(filters)
    end

    if character_namespace.before_index
      instance_exec &character_namespace.before_index
    end



    # pagination
    @objects = @objects.page(page).per(per_page)



    item_objects = @objects.map { |o| build_json_object(o) }

    # render json: {  objects:       item_objects,
    #                 total_pages:   @objects.total_pages(),
    #                 page:          page,
    #                 per_page:      per_page,
    #                 search_query:  search_query }

    render json: { objects: item_objects }
  end


  def show
    # TODO: Add an option to render custom template if the one
    #       is defined in the app for the model.
    @object = model_class.find(params[:id])
    render json: @object
  end


  # - right now form is build for the model automatically and
  #   all fields are using textinput.
  #   TODO: form should be autogenerated with smart field type
  #         inputs support.
  #   TODO: there should be a simple way to exclude or change
  #         type of fields in the autogenerated form, this could
  #         also work via coffeescript.
  def new
    @object = model_class.new
    render form_template
  end


  # - new action comment relates to edit action as well.
  def edit
    @object = model_class.find(params[:id])
    render form_template
  end


  # TODO: support of multiple object creation.
  def create
    @object = model_class.new params[form_attributes_namespace]

    if character_namespace.before_save
      instance_exec &character_namespace.before_save
    end

    if @object.save
      render json: build_json_object(@object)
    else
      # TODO: check if we need form_action_url and model_name here
      render form_template
    end
  end


  def update
    # TODO: support of multiple object update

    @object = model_class.find(params[:id])
    @object.assign_attributes params[form_attributes_namespace]

    if character_namespace.before_save
      instance_exec &character_namespace.before_save
    end

    if @object.save
      render json: build_json_object(@object)
    else
      # TODO: check if we need form_action_url and model_name here
      render form_template
    end
  end


  # TODO: support of multiple object delete.
  def destroy
    @object = model_class.find(params[:id])
    @object.destroy
    render json: 'ok'
  end

end



