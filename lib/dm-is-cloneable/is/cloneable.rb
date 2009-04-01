module DataMapper
  module Is
    module Cloneable
      
      module CloneSpec

        include DataMapper::Resource

        is :remixable

        property :id,                  Serial
        
        property :name,                String, :length => (1..64)
        property :description,         Text
        
        property :attributes_to_clone, String, :length => (1..1024), :auto_validation => false

        property :created_at,          DateTime
        property :updated_at,          DateTime
        property :deleted_at,          ParanoidDateTime

      end
      
      def is_cloneable(options = {})
        
        include InstanceMethods
        
        options = {
          :clone_specs        => true,
          :master_backlink_id => "master_#{Extlib::Inflection.foreign_key(self.name)}",
          :as                 => nil,
          :class_name         => "#{self}CloneSpec"
        }.merge(options)
        
        @clone_master_backlink_id = options[:master_backlink_id].to_sym
        class_inheritable_accessor :clone_master_backlink_id
                
        @clone_master_backlink = @clone_master_backlink_id.to_s.gsub!('_id','').to_sym
        class_inheritable_accessor :clone_master_backlink
        
        @cloneable_class_name = options[:class_name]
        class_inheritable_accessor :cloneable_class_name
        
        remix n, CloneSpec, :as => options[:as], :class_name => @cloneable_class_name
        
        @clone_spec_reader = Extlib::Inflection.tableize(@cloneable_class_name.snake_case).to_sym
        class_inheritable_accessor :clone_spec_reader
                
        @clone_spec_writer = "#{Extlib::Inflection.tableize(@cloneable_class_name.snake_case)}=".to_sym
        class_inheritable_accessor :clone_spec_writer
        
        if options[:as]
          self.class_eval(<<-EOS, __FILE__, __LINE__ + 1)
            alias #{@clone_spec_reader} #{options[:as]}
            alias #{@clone_spec_writer} #{options[:as]}=
          EOS
        end
        
        if @clone_master_backlink_id && properties.map{ |p| p.name }.include?(@clone_master_backlink_id)
          belongs_to @clone_master_backlink, :child_key => [@clone_master_backlink_id], :class_name => self.name
        end
        
        # support closing over values that are only accessible via self
        # this is necessary since we need these values in a context where self is a different object
        this, master_properties = self, self.properties.map { |p| p.name }
        
        enhance :clone_spec do
          
          validates_with_method :check_attributes_to_clone
          
          # use define_method to be able to close over 'this' and 'master_properties' from outer env
          define_method :check_attributes_to_clone do
            if !attributes_to_clone.empty? && attributes_to_clone.all? { |c| master_properties.include?(c) }
              true
            else
              [ false, "All attributes_to_clone must be properties of #{this.name}" ]
            end
          end
          
          # store an array of strings or a comma separated list of strings
          # storage format is a comma separated string with no whitespace
          def attributes_to_clone=(attrs)
            case attrs = (attrs.is_a?(self.class) ? attrs.attributes_to_clone : attrs)
            when String then attribute_set(:attributes_to_clone, attrs.gsub(' ', ''))
            when Symbol then attribute_set(:attributes_to_clone, attrs.to_s)
            when Array  then attribute_set(:attributes_to_clone, attrs.map { |a| a.to_s }.join(','))
            else
              raise ArgumentError, "attrs must be an Array or a String separated by commas but was #{attrs.class.name}, #{attrs}"
            end
          end
        
          # returns an array of strings representing the properties to be cloned
          def attributes_to_clone
            (attrs = attribute_get(:attributes_to_clone)) ? attrs.split(',').map { |a| a.to_sym } : []
          end
          
        end
        
      end
  
      module InstanceMethods
        
        def clone_resource(nr_of_clones = 1, attrs_to_clone = :all)
          
          only_clone = case attrs_to_clone
          when :all then []
          when ItemCloneSpec then attrs_to_clone.attributes_to_clone
          when Array then attrs_to_clone
          when String then attrs_to_clone.split(',').map { |a| a.to_sym }
          else 
            raise ArgumentError, 'attrs_to_clone must be one of [ :all | ItemCloneSpec | Array<String|Symbol> ]'
          end
          
          unless only_clone.all? { |a| self.attributes.include?(a) }
            # expensive second iteration only happens in errorneous codepath
            unknown_attributes = only_clone.select { |a| !self.attributes.include?(a) }
            raise ArgumentError, "#{self.class.name} has no properties named: #{unknown_attributes}"
          end
          
          clones = []
          nr_of_clones.times do
            clone = self.class.new
            cloned_attrs = self.attributes.except(:id)
            cloned_attrs.merge!(self.class.clone_master_backlink_id => self.id) if has_backlink_to_master?
            clone.update_attributes(cloned_attrs, *only_clone)            
            clones << clone
          end
          clones
        end
        
        def master_resource
          has_backlink_to_master? ? self.send(self.class.clone_master_backlink) : nil
        end
        
        def cloned_resources
          self.class.all(self.class.clone_master_backlink_id => self.id)
        end
        
        def has_backlink_to_master?
          (backlink_property = self.class.clone_master_backlink_id) ? self.respond_to?(backlink_property) : false
        end
        
        def has_clone_specs?
          !self.send(self.class.clone_spec_reader).empty?
        end
        
      end
      
    end
  end
end