# Character

**Character** is data management framework based on Backbone & Marionette written in CoffeeScript and backed with Rails.


## Configuration

To add model to the character add following lines in ```/app/assets/javascript/character.coffee```:

    #= require character/main
    #= require_self

    $ ->
        character.add_module 'Model_1'
        character.add_module 'Model_2'
        character.add_module 'Model_3'
        character.start()

Where ```Model_#``` are names of rails models.

## Foundation usage

At this point all basic layout is using custom style and colors. Foundation is used for menu (mobile) and rendering forms.