# Character (α)

**IN DEVELOPMENT**

Character is a set of development tools (framework) for empowering administration applications with a clean and simple user interfaces. Main goal of Character is to make developers life easier while building modern administration applications.

Core technologies that Character is built with: [Backbone.js](http://backbonejs.org) + [Marionette.js](https://github.com/marionettejs/backbone.marionette), [Foundation 5](http://foundation.zurb.com) and [Rails](http://rubyonrails.org).

![Character Demo](https://raw.github.com/slate-studio/character/master/doc/img/demo-1.jpg)

## Content

* [New Project](#new-project)
* [Authentification](#authentification)
  * [Mozilla Persona](#mozilla-persona)
  * [Login Background](#login-background)
* [Generic Application](#generic-application)
  * [Model Setup](#model-setup)
  * [Custom Form](#custom-form)
  * [Nested Form](#nested-form)
  * [Form Plugins](#form-plugins)
* [Character Namespaces](#character-namespaces)
* [Settings Application](#settings-application)
* [List of Dependencies](#list-of-dependencies)
* [TODO](#todo)


## New Project

Start new Rails project:

    rails _3.2.16_ new ProjectName -T -O

Add following gems to the ```Gemfile```:

    gem 'bson_ext'
    gem 'mongoid'
    gem 'asset_sync'
    gem 'character', github: 'slate-studio/character'
    # gem 'character', path: '../character'

Run ```bundle``` from projects root.

Create mongo database config, initialize Foundation (not required if it's not used in the project) and install Character assets and fixes:

    rails g mongoid:config
    rails g foundation:install
    rails g character:install

In one line:

    rails g mongoid:config ; rails g foundation:install ; rails g character:install

Character generator does:
1. Mounts character in the ```config/routes.rb``` with ```mount_character()``` command
2. Creates ```app/assets/javascript/admin.coffee```
3. Create ```app/assets/stylesheets/admin.scss```
4. Remove ```//= require_tree .``` and ```*= require_tree .``` string from ```app/assets/javascripts/application.js``` and ```app/assets/stylesheets/application.js``` — that's required to do not include admin assets in the application assets
5. Add character & foundation javascript assets to production environment in ```config/environment/production.rb```: ```config.assets.precompile += %w( admin.js admin.css foundation.js vendor/modernizr.js )```
6. Create character initializer ```config/initializers/character.rb```

Done! Check out ```localhost:3000/admin``` in the browser.

## Authentification

#### Mozilla Persona

Character is using [Mozilla Persona](https://login.persona.org/about) as main authentification system. This one chosen as it is very easy to setup and allows us to do not create administrative accounts from one project to another.

While logging to Character for the first time, first administrative account is created. Add other accounts via console or using Character / Settings / Admins tab.


#### Login Background

Default login background could be changed using ```config.login_background_image``` option in Character configuration file ```config/initializers/character.rb```.

![Character Default Login](https://raw.github.com/slate-studio/character/master/doc/img/demo-3.jpg)


## Generic Application

Generic application is a main type of Character apps. It provides a way to setup administrative application for any [Mongoid](http://mongoid.org/en/mongoid/index.html) model in no time.

[Generic Application API Reference](https://github.com/slate-studio/character/blob/master/doc/generic_application.md)

![Character Generic Application Demo](https://raw.github.com/slate-studio/character/master/doc/img/demo-2.jpg)

#### Model Setup

Here is an example of adding character app for ```Project``` model from the screenshot above. All model setups are added to ```app/assets/javascripts/admin.coffee```:

    new GenericApplication 'Project',
      icon:         'rocket'
      reorderable:  true
      index_scopes:
        default:    '_position:desc'

Projects app added to character with ```rocket``` menu icon from [Fontawesome Icons](http://fontawesome.io/icons/), default sort order uses ```_position``` model field, and items are reorderable in the list with drag'n'drop to make it possible to reorder projects from the portfolio page.

#### Custom Form

By default object forms are autogenerated, [here](https://github.com/slate-studio/character/blob/master/app/views/character/admin/generic_form.html.erb) is a template with is used to do that. At this point it's very simple generator and we have a plan to make more sophisticated. So you might want to customize objects form and it's pretty easy to do this.

Character looks for forms templates at ```app/views/character/admin/pluralized_model_name/form.html.erb```, so in the example above form should be placed at: ```app/views/character/admin/projects/form.html.erb```. Generic template is good to start customization with:

    <%= simple_form_for @object, url: @form_action_url do |f| %>
      <div class='row chr-row-border chr-details-padding'>
        <div class='small-12 columns'>
          <h5><%= @model_name %> <small>attributes</small></h5>
        </div>

        <% @form_fields.each do |name| %>
          <%= f.input name, wrapper_class: 'small-12 columns' %>
        <% end %>
      </div>

      <div class='row'>
        <div class='small-12 columns'>
          <%= f.button :submit, class: 'chr-btn-submit radius secondary' %>
        </div>
      </div>
    <% end %>

Two things to note in this template: 1. [Simple Form]() is used as form generation tool; 2. It's important for submit button to have ```chr-btn-submit``` class.

#### Nested Form

[Nested Form](https://github.com/ryanb/nested_form) is a very handy gem to expand forms with editable inlines. It plays very nice with Character, just add ```#= require jquery_nested_form``` to ```app/assets/javascript/character``` and that's it. Customized form could include nested forms. Following screenshot shows part of the Project form -- editable list of embeded images into the Project model handled by [Nested Form](https://github.com/ryanb/nested_form).

![Character Nested Forms Demo](https://raw.github.com/slate-studio/character/master/doc/img/demo-4.jpg)

#### Form Plugins

One of core ideas of Character is simplicity of integration any kind of jQuery plugins. Plugins could be initiated using scoped form events, for Projects example from above the event is named: ```character.projects.details.form.rendered```.

Here is how [jQuery UI sortable](http://jqueryui.com/sortable/) plugin attached to the project form to provide a way to change image position with drag'n'drop. This code is put to the bottom of ```app/assets/javascript/admin.js.coffee```:

    $ ->
      # Make it possible to change the order of images for projects with drag'n'drop

      $(document).on 'character.projects.details.form.rendered', (e, el) ->
        list = $(el).find('#image_items')

        sort_options =
          stop: (e, ui) ->
            items = list.find('.fields')
            total = items.length
            items.each (index, el) ->
              $(el).find('.project_images__position input').val(total - index)

        list.sortable(sort_options).disableSelection()


## Character Namespaces

Namespaces allow you to use several independent character app instances for one website. Each of them will be using separate configuration, styles and templates.

[See namespaces section for details](https://github.com/slate-studio/character/blob/master/doc/namespaces.md)


## Settings Application

Settings application provides a generic way of expanding admin with editable sets of parameters (objects) or editable collections. One of good examples of usage of settings app is an admin application which allows to add/remove administrators:

![Character Nested Forms Demo](https://raw.github.com/slate-studio/character/master/doc/img/demo-5.jpg)

Settings could be used to provide a simple way of editing CTAs, webpage editable content, etc. Read more on Character Settings [here](https://github.com/slate-studio/character_settings).

## List of Dependencies

Frontend Javascript:

* [jQuery](https://github.com/rails/jquery-rails)
* [Underscore](https://github.com/rweng/underscore-rails)
* [Underscore String](https://github.com/epeli/underscore.string)
* [Backbone](http://backbonejs.org/)
* [Backbone Marionette](https://github.com/chancancode/marionette-rails)
* [jQuery UI](https://github.com/joliss/jquery-ui-rails)
* [Moment.js](http://momentjs.com)

Frontend CSS:

* [Compass](https://github.com/Compass/compass-rails)
* [Foundation](https://github.com/zurb/foundation/)
* [Fontawesome](https://github.com/bokmann/font-awesome-rails)

Backend:

* [BrowserID](https://github.com/alexkravets/browserid-auth-rails)
* [Simple Form](https://github.com/plataformatec/simple_form)
* [Nested Forms](https://github.com/ryanb/nested_form)
* [Kaminari](https://github.com/amatsuda/kaminari)


## Running Tests

To run the tests use the following command in the gem's root directory:

    $ rake test


## TODO

* notifications
* hotkeys
* ipad
* iphone
* translations
* annotate sources

--
* [Олександр Кравець](http://www.bits.in.ua) @ [Slate](http://www.slatestudio.com) - December 16, 2013
* Роман Лупійчук @ [Slate](http://www.slatestudio.com) - August 9, 2013
* Мельник Максим @ [Slate](http://www.slatestudio.com) - October 23, 2013
