require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

if HAS_SQLITE3 || HAS_MYSQL || HAS_POSTGRES
  
  describe DataMapper::Is::Cloneable do
    
    include ModelSetup
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
  
    describe "every cloneable", :shared => true do
      
      it "should define a #clone_resource instance method" do
        @i1.respond_to?(:clone_resource).should be_true
      end
            
      it "should define a #master_resource instance method" do
        @i1.respond_to?(:master_resource).should be_true
      end
            
      it "should define a #cloned_resources instance method" do
        @i1.respond_to?(:cloned_resources).should be_true
      end
            
      it "should define a #has_backlink_to_master? instance method" do
        @i1.respond_to?(:has_backlink_to_master?).should be_true
      end
            
      it "should define a #has_clone_specs? instance method" do
        @i1.respond_to?(:has_clone_specs?).should be_true
      end

      # TODO extract these since they depend on the remixed class name

      it "should define a remixed model that can be auto_migrated" do
        # once it's migrated it stays in the database and can be used by the other specs
        Object.const_defined?("ItemCloneSpec").should be_true
        lambda { ItemCloneSpec.auto_migrate! }.should_not raise_error
      end
      
      it "should define a 'cloneable_class_name' class_level reader on the remixing model" do
        Item.respond_to?(:cloneable_class_name).should be_true
        Item.cloneable_class_name.should == "ItemCloneSpec"
      end      
            
      it "should define a 'clone_spec_reader' class_level reader on the remixing model" do
        Item.respond_to?(:clone_spec_reader).should be_true
        Item.clone_spec_reader.should == :item_clone_specs
      end
                  
      it "should define a 'clone_spec_writer' class_level reader on the remixing model" do
        Item.respond_to?(:clone_spec_writer).should be_true
        Item.clone_spec_writer.should == :item_clone_specs=
      end
      
      it "should respond_to?(:item_clone_specs)" do
        @i1.respond_to?(:item_clone_specs).should be_true
      end
      
      it "should store a collection of clone_specs" do
        @i1.item_clone_specs.should be_empty
      end
      
      it "should keep track of timestamps" do
        @i1.item_clone_specs.create(:name => "foo", :attributes_to_clone => [ :name, :description ])
        @i1.item_clone_specs[0].should respond_to(:created_at)
        @i1.item_clone_specs[0].should respond_to(:updated_at)
        @i1.item_clone_specs[0].should respond_to(:deleted_at)
      end

    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------

    describe "every cloneable that has an alias on the cloneable association", :shared => true do

      it "should set the specified alias on the default 'clone_specs' reader" do
        @i1.respond_to?(:my_item_clone_specs).should be_true
      end

    end
    
    describe "every cloneable that has no alias on the cloneable association", :shared => true do

      it "should respond to the default 'clone_specs' reader" do
        @i1.respond_to?(:item_clone_specs).should be_true
      end

    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
    
    
    describe "Item.is(:cloneable)" do
    
      before do
      
        unload_testing_models "ItemCloneSpec", "Item"
        
        class Item

          include DataMapper::Resource

          property :id,          Serial

          property :name,        String
          property :description, String
          
          is :cloneable

        end
        
        Item.auto_migrate!
        ItemCloneSpec.auto_migrate!

        @i1 = Item.create(:id => 1)
      
      end
    
      it_should_behave_like "every cloneable"
      it_should_behave_like "every cloneable that has no alias on the cloneable association"
    
    end

    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
        
    describe "Item.is(:cloneable, :as => :my_item_clone_specs)" do
    
      before do
      
        unload_testing_models "ItemCloneSpec", "Item"
        
        class Item

          include DataMapper::Resource

          property :id,          Serial

          property :name,        String
          property :description, String

          is :cloneable, :as => :my_item_clone_specs

        end
      
        
        Item.auto_migrate!
        ItemCloneSpec.auto_migrate!
    
        @i1 = Item.create(:id => 1)
      
      end
    
      it_should_behave_like "every cloneable"
      it_should_behave_like "every cloneable that has an alias on the cloneable association"
    
    end
    
    
    describe "Item#clone" do
      
      before do
      
        unload_testing_models "ItemCloneSpec", "Item"
      
        class Item

          include DataMapper::Resource

          property :id,          Serial

          property :name,        String
          property :description, String
          
          is :cloneable

        end
        
        Item.auto_migrate!
        ItemCloneSpec.auto_migrate!
      
      end
    
      describe "with no parameters" do
      
        it "should produce one clone with all public properties copied over" do
          
          i = Item.create(:id => 1, :name => "name", :description => "description")
          Item.all.size.should == 1
          
          clones = i.clone_resource
          
          Item.all.size.should == 2
          clones[0].name.should == 'name'
          clones[0].description.should == 'description'
        
        end
      
      end
        
      describe "with one parameter" do
      
        it "should produce the given number of clones with all public properties copied over" do
          
          i = Item.create(:id => 1, :name => "name", :description => "description")
          Item.all.size.should == 1
          
          clones = i.clone_resource(2)
          
          Item.all.size.should == 3
          (0..1).each do |idx|
            clones[idx].name.should == 'name'
            clones[idx].description.should == 'description'
          end
          
        end
      
      end
         
      describe "with two parameters, the last being an instance of ItemCloneSpec" do
      
        it "should produce the given number of clones with all given properties copied over" do
          
          i = Item.create(:id => 1, :name => "name", :description => "description")
          
          s = i.item_clone_specs.create :name => "test clone spec", :attributes_to_clone => [ :name ]
          
          Item.all.size.should == 1
          ItemCloneSpec.all.size.should == 1
          
          clones = i.clone_resource(2, s)
          
          Item.all.size.should == 3
          (0..1).each do |idx|
            clones[idx].name.should == 'name'
            clones[idx].description.should be_nil
          end
        
        end
      
      end
               
      describe "with two parameters, the last being an instance of Array" do
      
        it "should produce the given number of clones with all given properties copied over" do
          
          i = Item.create(:id => 1, :name => "name", :description => "description")
          s = i.item_clone_specs.create :name => "test clone spec", :attributes_to_clone => [ :name ]
          Item.all.size.should == 1
          ItemCloneSpec.all.size.should == 1
          
          clones = i.clone_resource(2, i.item_clone_specs.first.attributes_to_clone)
          
          Item.all.size.should == 3
          (0..1).each do |idx|
            clones[idx].name.should == 'name'
            clones[idx].description.should be_nil
          end
        
        end
      
      end
      
      describe "with two parameters, the last being an instance of String" do

        it "should produce the given number of clones with all given properties copied over" do

          i = Item.create(:id => 1, :name => "name", :description => "description")
          s = i.item_clone_specs.create :name => "test clone spec", :attributes_to_clone => [ :name ]
          Item.all.size.should == 1
          ItemCloneSpec.all.size.should == 1

          clones = i.clone_resource(2, "name")

          Item.all.size.should == 3
          (0..1).each do |idx|
            clones[idx].name.should == 'name'
            clones[idx].description.should be_nil
          end

        end
        
      end
      
      describe "with two parameters, the last being an instance of an unrecognized type" do

        it "should produce the given number of clones with all given properties copied over" do

          i = Item.create(:id => 1, :name => "name", :description => "description")
          Item.all.size.should == 1          
          lambda { i.clone_resource(2, { :foo => :bar }) }.should raise_error(ArgumentError)
          Item.all.size.should == 1

        end

      end
            
      describe "with two parameters, the last being an unknown property" do

        it "should produce the given number of clones with all given properties copied over" do

          i = Item.create(:id => 1, :name => "name", :description => "description")
          Item.all.size.should == 1          
          lambda { i.clone_resource(2, "foo") }.should raise_error(ArgumentError)
          Item.all.size.should == 1

        end

      end
    
    end
    
    describe "Item#has_clone_specs?" do
      
      before do
        
        unload_testing_models "ItemCloneSpec", "Item"
        
        class Item

          include DataMapper::Resource

          property :id,          Serial

          property :name,        String
          property :description, String
          
          is :cloneable

        end
        
        Item.auto_migrate!
        ItemCloneSpec.auto_migrate!
        
        @i = Item.create
        
      end
      
      it "should return false if no clone_specs are present" do
        @i.has_clone_specs?.should be_false
      end
            
      it "should return true if at least one clone_spec is present" do
        @i.item_clone_specs.create :name => "test clone spec", :attributes_to_clone => [ :name ]
        @i.has_clone_specs?.should be_true
      end
      
    end

    describe "Item#has_backlink_to_master?" do
      
      describe "with backlink id property defined" do
      
        before do
        
          unload_testing_models "ItemCloneSpec", "Item"
        
          class Item

            include DataMapper::Resource

            property :id,             Serial
            property :master_item_id, Integer

            property :name,           String
            property :description,    String
          
            is :cloneable

          end
        
          Item.auto_migrate!
          ItemCloneSpec.auto_migrate!
        
          @i = Item.create
        
        end
            
        it "should return true" do
          @i.has_backlink_to_master?.should be_true
        end
      
      end
      
      describe "without backlink id property defined" do
      
        before do
        
          unload_testing_models "ItemCloneSpec", "Item"
        
          class Item

            include DataMapper::Resource

            property :id,             Serial

            property :name,           String
            property :description,    String
          
            is :cloneable

          end
        
          Item.auto_migrate!
          ItemCloneSpec.auto_migrate!
        
          @i = Item.create
        
        end
            
        it "should return false" do
          @i.has_backlink_to_master?.should be_false
        end
      
      end
      
    end
    
    describe "Item#master_resource" do
      
      describe "when sent to an object which is no clone" do
      
        before do
        
          unload_testing_models "ItemCloneSpec", "Item"
        
          class Item

            include DataMapper::Resource

            property :id,             Serial
            property :master_item_id, Integer

            property :name,           String
            property :description,    String
          
            is :cloneable

          end
        
          Item.auto_migrate!
          ItemCloneSpec.auto_migrate!
        
          @i = Item.create
        
        end
            
        it "should return nil" do
          @i.master_resource.should be_nil
        end
      
      end
      
      describe "when sent to an object which is a clone" do
      
        before do
        
          unload_testing_models "ItemCloneSpec", "Item"
        
          class Item

            include DataMapper::Resource

            property :id,             Serial
            property :master_item_id, Integer

            property :name,           String
            property :description,    String
          
            is :cloneable

          end
        
          Item.auto_migrate!
          ItemCloneSpec.auto_migrate!
        
        end
            
        it "should return the correct master object" do
          i = Item.create
          c = i.clone_resource.first
          i.has_backlink_to_master?.should be_true
          c.master_resource.should == i
        end
      
      end
      
    end
    
    describe "Item#cloned_resources" do
      
      describe "when sent to an object which has no clones" do
      
        before do
        
          unload_testing_models "ItemCloneSpec", "Item"
        
          class Item

            include DataMapper::Resource

            property :id,             Serial
            property :master_item_id, Integer

            property :name,           String
            property :description,    String
          
            is :cloneable

          end
        
          Item.auto_migrate!
          ItemCloneSpec.auto_migrate!
        
        end
            
        it "should return an empty Array" do
          Item.create.cloned_resources.should be_empty
        end
      
      end
      
      describe "when sent to an object which has one or more clones" do
      
        before do
        
          unload_testing_models "ItemCloneSpec", "Item"
        
          class Item

            include DataMapper::Resource

            property :id,             Serial
            property :master_item_id, Integer

            property :name,           String
            property :description,    String
          
            is :cloneable

          end
        
          Item.auto_migrate!
          ItemCloneSpec.auto_migrate!
        
        end
            
        it "should return an array of all cloned objects" do
          i = Item.create
          i.cloned_resources.should be_empty
          
          c = i.clone_resource.first
          
          i.cloned_resources.should have(1).item
          i.cloned_resources.first.should == c
        end
      
      end
      
    end
    
  end
  
end
