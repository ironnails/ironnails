require File.dirname(__FILE__) + "/collections"
module IronNails
  
  module View
    
    class ViewModelBuilder
      
      # gets the view model instance to manipulate with this builder
      attr_reader :model
      
      # loads a new instance of the view into memory
      def set_view_name(name)
        model.set_view_name name
      end
      
      # gets the view proxy      
      def view
        model.view
      end
      
      def show_view
        model.show_view
      end 
      
      def add_command_to_view(cmd_def)
        norm = normalize_command_definitions(cmd_def)
        model.add_commands_to_queue CommandCollection.generate_for(norm, model)
      end
      
      #      def view_instance
      #        @model.view_instance
      #      end
      
      def viewmodel_class
        @model.class
      end 
      
      def synchronise_viewmodel_with_controller
        model.synchronise_viewmodel_with_controller
      end 
      
      def synchronise_to_controller(controller)
        objects = controller.instance_variable_get "@objects"
        properties = model.to_clr_type.get_properties.collect { |pi| pi.name.to_s.to_sym }
        objects.each do |k,v|
          if properties.include? k.to_s.camelize.to_sym 
            val = model.send(k)
            objects[k] = val
            controller.instance_variable_set "@{k}", val
          end
        end
        
      end
      
      # Generates the command definitions for our view model.
      def normalize_command_definitions(definitions)
        command_definitions = {}
        
        definitions.each do |k, v|
          command_definitions[k] = normalize_command_definition(k, v)
        end unless definitions.nil?
        
        command_definitions        
      end 
      
      # Generates a command definition for our view model.
      # When it can't find a key :action in the options hash for the view_action
      # it will default to using the name as the command as the connected option.
      # It will generate a series of commands for items that have more than one trigger      
      def normalize_command_definition(name, options)
        mode = options[:mode]
        act = options[:action]||name
        action = act
        action = method(act) if act.is_a?(Symbol) || act.is_a?(String)
        
        if options.has_key?(:triggers) && !options[:triggers].nil?
          triggers = options[:triggers]
          
          cmd_def = 
          if  triggers.is_a?(String) || triggers.is_a?(Symbol)
            { 
              :element => triggers, 
              :event   => :click, 
              :action  => action,
              :mode    => mode,
              :type    => :event
            } 
          elsif triggers.is_a?(Hash)          
            triggers.merge({:action => action, :mode => mode, :type => :event }) 
          elsif triggers.is_a?(Array)
            defs = []
            triggers.each do |trig|
              trig = { :element => trig, :event => :click } unless trig.is_a? Hash
              trig[:event] = :click unless trig.has_key? :event
              defs << trig.merge({ :action => action, :mode => mode, :type => :event })
            end 
            defs
          end
          cmd_def
        else
          exec = options[:execute]
          execute = exec
          execute = method(exec) if exec.is_a?(Symbol) || exec.is_a?(String)
          controller_action, controller_condition = execute || action, options[:condition]
          {
            :action => controller_action,
            :condition => controller_condition,
            :mode => mode,
            :type => :behavior
          }
        end 
      end
      
      # builds a class with the specified +class_name+ and defines it if necessary. 
      # After it will load the proxy for the view with +view_name+
      def build_class_with(options)
        # FIXME: The line below will be more useful when we can bind to IronRuby objects
        # Object.const_set options[:class_name], Class.new(ViewModel) unless Object.const_defined? options[:class_name]     
        
        # TODO: There is an issue with namespacing and CLR classes, they aren't registered as constants with
        #       IronRuby. This makes it hard to namespace viewmodels. If the namespace is included everything 
        #       should work as normally. Will revisit this later to properly fix it.        
        klass = Object.const_get options[:class_name]
        klass.include IronNails::View::ViewModelMixin
        @model = klass.new 
        model.set_refresh_view &options[:refresh]
        model.set_synchronise_viewmodel &options[:synchronise]
        set_view_name options[:view_name]      
        
        model
      end
      
      def initialize_with(command_definitions, objects)
        definitions = normalize_command_definitions command_definitions
        model.add_commands_to_queue CommandCollection.generate_for(definitions, model)
        model.model_queue = ModelCollection.generate_for(objects)
      end
      
      class << self
        
        # initializes a new view model class for the controller 
        def for_view_model(options)
          builder = new
          builder.build_class_with options
          builder
        end       
        
      end
      
    end
    
  end
  
end