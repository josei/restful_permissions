module RestfulPermissions
  DefaultActions = {:new=>:new, :show=>:show, :edit=>:edit, :creat=>:create, :updat=>:update, :destroy=>:destroy}

  class Violation < StandardError; end

  module Permissions    
    def self.included base
      base.extend ClassMethods
      base.singleton_class.module_eval do
        define_method :method_added do |m|
          if m.to_s =~ /\A(\w+)able_by\?\Z/ 
            permission_action_detected $1
          end
        end
      end
    end

    module ClassMethods
      def permission_action_detected root
        action = RestfulPermissions.get_action root
        add_permission_helpers action, root
      end
      
      def add_permission_helpers action, root
        code = <<-NEW_METHOD
          def about_to_#{action}_by! actor
            about_to_action :#{action}, :#{root}, actor
          end
          def #{action}_by! actor, options={}, &block
            perform_action :#{action}, :#{root}, actor, options, &block
          end
          NEW_METHOD
        
        class_eval code
      end
    end
    
    protected
    def about_to_action action, root, actor
      raise Violation, "#{root}able_by?".to_sym unless self.send "#{root}able_by?".to_sym, actor
    end
    
    def perform_action action, root, actor, options={}, &block
      send "#{action}_by".to_sym, actor if respond_to? "#{action}_by".to_sym
      about_to_action action, root, actor
      if block_given?
        transaction &block
      elsif options[:with] # Method name is provided
        self.send options[:with]
      elsif action.to_sym == :destroy
        self.destroy
      else
        self.save
        self
      end
    end
  end

  # Gets from "updat" or "cancell" to "update" or "cancel"
  def self.get_action root
    action = DefaultActions[root.to_sym]
    return action unless action.nil?
    if root.to_s =~ /\A(\w*[aeiou])([bgklm]){2}\Z/
      :"#{$1}#{$2}" # Remove repetition
    elsif root.to_s =~ /(\w*[cdfgjklmnpqrstvwxz][aeiou][dkmt])\Z/
      :"#{$1}e" # Add trailing "e"
    else
      root.to_sym
    end
  end
end