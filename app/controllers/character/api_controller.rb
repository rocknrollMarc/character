# Author: Alexander Kravets
#         Slate, 2013

#
# TODO: split filters into separate module
#

class Character::ApiController < ActionController::Base
  # Generic API

  layout false

  # Filters -----------------------------------------------

  before_filter :authenticate_admin_user
  before_filter :set_model_class
  before_filter :set_form_template,         only:   %w( new edit create update )
  before_filter :set_form_fields
  before_filter :map_character_item_fields
  before_filter :set_fields_to_include,     only:   %w( index create update )

  def authenticate_admin_user
    @admin_user = browserid_current_user if browserid_authenticated?
  end

  # TODO: for api calls return 500 if user is not loggedin

  # - sets model class to be used in actions, class name is defined
  #   in URL with a slag where - replaced by ::, for example:
  #   Character::BlogPost would be /api/Character-BlogPost/new

  def set_model_class
    # Generating class name from the url slug, where '::' replaced with '-'
    # For example: Character-Post -> Character::Post
    @model_slug  = params[:model_slug]
    @model_class = @model_slug.gsub('-', '::').constantize
    # model name is used while template rendering
    @model_name  = @model_slug.split('-').last.split(/(?=[A-Z])/).join(' ')
    # namespace is used while form processing
    @namespace   = @model_class.name.underscore.gsub('/', '_').to_sym
  end

  # - this helper provides way to redefine defaults templates to be
  #   used for form-template based actions mentioned above

  def set_form_template
    template_folder = @model_class.name.underscore.to_s.pluralize

    if template_folder.start_with? 'character/'
      template_folder = 'character/' + template_folder.gsub('character/', '').gsub('/', '/admin/')
    else
      template_folder = 'character/admin/' + template_folder
    end

    # Check if there is a custom form template for the class in the
    # character/ folder, if not using generic form

    if template_exists?("form", template_folder, false)
      @form_template = "#{ template_folder }/form"
    else
      @form_template = "character/admin/generic_form"
    end
  end


  # Helpers -----------------------------------------------

  def set_form_fields
    @form_fields = @model_class.fields.keys - %w( _id _type created_at _position _keywords updated_at deleted_at )
  end


  def map_character_item_fields
    @character_item_fields = {}

    fields = @model_class.fields.keys - %w( _id _type _position _keywords created_at updated_at deleted_at )


    # TODO: add a warning message here

    if params[:title_field]
      @character_item_fields[:title_field] = params[:title_field]
    else
      if fields.size > 0
        @character_item_fields[:title_field] = fields[0]
      else
        puts "WARNING: #{ @model_class } model doesn't have any unique fields."
      end
    end


    if params[:meta_field]
      @character_item_fields[:meta_field] = params[:meta_field]
    else
      if fields.size > 1
        @character_item_fields[:meta_field] = fields[1]
      end
    end


    if @model_class.method_defined? :character_thumb_url
      @character_item_fields[:image_field] = :character_thumb_url 
    end
  end

  def set_fields_to_include
    @fields_to_include = if params[:fields_to_include]
      params[:fields_to_include].split(',')
    else
      []
    end
  end


  # This builds an object which is used as character internal
  # model in index view and headers.
  def build_character_item(o)
    # Until we don't have a format for requesting model attributes
    # use the first attribute of the model.

    # Here we exclude meta fields to have more chances to get
    # descriptive field for the admin index

    fields = @character_item_fields
    hash   = { _id: o.id }

    if fields.has_key? :title_field
      hash[:__title] = o.try(fields[:title_field])
    end

    if fields.has_key? :meta_field
      hash[:__meta] = o.try(fields[:meta_field])
    end
    
    if fields.has_key? :image_field
      hash[:__image] = o.try(fields[:image_field])
    end

    @fields_to_include.each do |f|
      hash[f] = o.try(f)
    end

    if params[:reorderable] == 'true'
      hash[:_position] = o.try(:_position)
    end

    updated_at = o.try(:updated_at)
    if updated_at
      # TODO: add smart formatting options here
      hash[:__updated_at] = updated_at.to_formatted_s(:long_ordinal)
    end

    hash
  end


  # Actions -----------------------------------------------

  # - the index action implements order, search and paging
  def index
    order_by     = params[:order_by]
    search_query = params[:search_query] || ''
    page         = params[:page]         || 1
    per_page     = params[:per_page]     || 50

    @objects = @model_class.unscoped.all

    # order_by format: &order_by=field_name:direction,field_name2:direction,...&
    if order_by
      filters = {}
      order_by.split(',').each do |filter|
        filter_options = filter.split(':')
        filters[filter_options.first] = filter_options.last
        @fields_to_include.append(filter_options.first)
      end
      
      @objects = @objects.order_by(filters)
    end
    

    #@objects = @objects.full_text_search(search_query) if not search_query.empty?
    #@objects = @objects.page(page).per(per_page)

    item_objects = @objects.map { |o| build_character_item(o) }

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
    @object = @model_class.find(params[:id])
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
    @form_action_url = "/admin/#{ @model_slug }"
    @object = @model_class.new
    render @form_template
  end


  # - new action comment relates to edit action as well.
  def edit
    @object = @model_class.find(params[:id])
    @form_action_url = "/admin/#{ @model_slug }/#{ @object.id }"
    render @form_template
  end


  # TODO: support of multiple object creation.
  def create
    @object = @model_class.create params[@namespace]

    if @object.save
      render json: build_character_item(@object)
    else
      render @form_template
    end
  end


  def update
    # TODO: support of multiple object update

    @object = @model_class.find(params[:id])

    if @object.update_attributes params[@namespace]
      render json: build_character_item(@object)
    else
      render @form_template
    end
  end


  # TODO: support of multiple object delete.
  def destroy
    @object = @model_class.find(params[:id])
    @object.destroy
    render json: 'ok'
  end
end


