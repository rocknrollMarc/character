# Author: Alexander Kravets
#         Slate, 2013

class Character::Admin::ApiController < Character::Admin::BaseController
  # Generic API for Character::Admin models

  # Filters -----------------------------------------------

  before_filter :set_model_class
  # - sets model class to be used in actions, class name is defined
  #   in URL with a slag where - replaced by ::, for example:
  #   Character::BlogPost would be /api/Character-BlogPost/new

  def set_model_class
    # Generating class name from the url slug, where '::' replaced with '-'
    # For example: Character-Post -> Character::Post
    @model_slug  = params[:model_slug]
    @model_class = @model_slug.gsub('-', '::').constantize
    @namespace   = @model_class.name.underscore.gsub('/', '_').to_sym
  end


  before_filter :set_form_template, only: %w( new edit create update )
  # - this helper provides way to redefine defaults templates to be
  #   used for form-template based actions mentioned above

  def set_form_template
    template_folder = @namespace.to_s.pluralize

    # Check if there is a custom form template for the class in the
    # character/admin/ folder, if not using generic form

    if template_exists?("form", "character/admin/#{ template_folder }", false)
      @form_template = "character/admin/#{ template_folder }/form"
    else
      @form_template = "character/admin/api/generic_form"
    end
  end


  # TODO: revise when switch to devise
  before_filter :set_admin_user_id, only: %w( create update )
  # - this looks like some hackish way to track changes done by admin,
  #   it is not generic at all and should be revised by porting to devise.
  #   Not sure what this is used for.

  def set_admin_user_id
    params[@namespace][:admin_user_id] = @character_admin_user.id
  end


  # Actions -----------------------------------------------


  # - the index action implements search and paging functionality.
  #   TODO: instead of returning a full object scheme, return only
  #         predefined set of fields.
  #   IDEA: fields and template for index view could be defined in
  #         coffeescript admin file, where list of required fields
  #         is passed to the action as parameter.
  def index
    search_query  = params[:search_query] || ''
    page          = params[:page]         || 1
    per_page      = params[:per_page]     || 10

    @objects = @model_class.all

    @objects = @objects.full_text_search(search_query) if not search_query.empty?
    @objects = @objects.page(page).per(per_page)

    # TODO: here we should implement logic of objects transform to
    #       json list and check if all provided attribute names are
    #       available, if some is not available provide an error
    #       handler.


    # Until we don't have a format for requesting model attributes
    # use the first attribute of the model.

    # Here we exclude meta fields to have more chances to get
    # descriptive field for the admin index
    fields = @model_class.fields.keys - %w( _id _type created_at _position _keywords updated_at deleted_at )

    title_field = fields[0]
    image_field = :admin_thumb_url if @model_class.method_defined? :admin_thumb_url

    
    if @model_class.method_defined? :admin_thumb_url
      mapped_objects = @objects.map {|o| {_id:o.id,title:o.try(title_field),image:o.admin_thumb_url}}
    else
      mapped_objects = @objects.map {|o| {_id:o.id,title:o.try(title_field)} }    
    end

    render json: {  objects:       mapped_objects,
                    total_pages:   @objects.total_pages(),
                    page:          page,
                    per_page:      per_page,
                    search_query:  search_query }
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
    @object  = @model_class.new
    render @form_template, layout: false
  end  


  # - new action comment relates to edit action as well.
  def edit
    @object = @model_class.find(params[:id])
    render @form_template, layout: false
  end


  # TODO: support of multiple object creation.
  def create
    @object = @model_class.create params[@namespace]

    if @object.save
      render json: @object
    else
      render @form_template, layout: false
    end
  end


  # TODO: support of multiple object update.
  def update
    @object = @model_class.find(params[:id])
    
    if @object.update_attributes params[@namespace]
      render json: @object
    else
      render @form_template, layout: false
    end
  end


  # TODO: support of multiple object delete.
  def destroy
    @object = @model_class.find(params[:id])
    @object.destroy
    render json: 'ok'
  end


  # TODO: this method may be implemented using an update call
  #       with a set of ids and attributes to update, this will
  #       involve some frontend logic changes as well.
  def reorder
    # TODO: need to add reordarable check
    @model_class.reorder(params[:ids])
    render json: 'ok'
  end  
end


