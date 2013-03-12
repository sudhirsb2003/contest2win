module ActionView
  module Helpers
    module ActiveRecordHelper
      # Override ActionView::error_messages_for but can print errors for
      # multiple objects and permits customized display values for field names
      #
      # creates a div with error messages of all object(s) in object_list
      # 
      # object_list is an activerecord or array of active records
      # options
      #   :sub a hash of options to replace the name with.
      #   Ex. :primary_text_message_address_text=>'Phone number' replaces the message
      #       generated on primary_text_message_address_text to use 'Phone number' instead
      #
      #   :class=> class of the div. Default errorExplanation
      #   :id=> id of the div. Default errorExplanation
      #   :header => header text. default H2
      #   
      #   :header_message (optional) - the top title message. Can use %d is replaced by %d
      #     default is: %d prohibited this "object_name" from being saved
      #   :header_sub_message (optional) - the second title that appears above the messages
      #     default is 'There were problems with the following fields:'
    
          
      def error_messages_for(object_list, options = {})
        if object_list.is_a?(Array)
          object_list = object_list.map{|o| o.to_s}
        else
          object_list = object_list.to_s
        end  
        return "" if object_list.nil?
        
        options = options.symbolize_keys
        
        bullets,main_obj_name = bullets_from_errors(object_list, options)
        
        if !bullets.blank?
           #default to standard error message. replace the ${NUM_ERRORS} with the number of errors.
           options[:header_message] ||= "%d errors prohibited this %1 from being saved".gsub('%1',"#{(main_obj_name || 'object')}")
           options[:header_message] = options[:header_message] % bullets.length
           
           content_tag("div",
              content_tag( options[:header_tag] || "h2", options[:header_message]) +
              content_tag("p", (options[:header_sub_message] || "There were problems with the following fields:")) +
              content_tag("ul", "#{bullets}"),
              "id" => options[:id] || "errorExplanation", "class" => options[:class] || "errorExplanation"
           )
        else
          ""
        end
      end
      
       def bullets_from_errors(object_list,options)
    
        subs = options[:sub] ? options[:sub].stringify_keys : {}
        options[:skip] ||= []
        main_obj_name = nil
        
        #create a list of bullets (html <li> tags) by concating the objects
        bullets= [object_list].flatten.inject([]) do |msg_list,object|
        
          #if it is a string get the instance variable
          if object.kind_of?(String)
            main_obj_name ||= "#{object.to_s.gsub("_", " ")}" 
            object = instance_variable_get("@#{object}")
          elsif object
            main_obj_name ||= object.class.to_s.titleize.downcase
          end
             
          #if the object exists and responds has errors append each error to the list
          if (object && object.respond_to?('errors') && !object.errors.empty?) 
            object.errors.each do |attr, msg| 
               if (!options[:skip].include?(attr.to_s))
                 obj_name = (subs[attr] || "#{attr == 'base' ? '' : object.class.human_attribute_name(attr)}")
                 #replace the field names with the names specified in the subs hash
                 msg_list << content_tag('li', "#{obj_name} #{msg}")
               end
            end
             
            
          end
          msg_list
        end
        
        return bullets, main_obj_name
      end
    end
  end
end



  
