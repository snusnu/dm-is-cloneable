require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

if HAS_SQLITE3 || HAS_MYSQL || HAS_POSTGRES
  
  describe DataMapper::Is::Cloneable do
    
    include ModelSetup
    
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

      @i = Item.create(:id => 1)
      @s = @i.item_clone_specs.build :name => "test clone spec"
      
    end
    
    describe "ItemCloneSpec#attributes_to_clone=" do

      it "should not allow to be called with nil as parameter" do
        
        lambda { @s.attributes_to_clone = nil }.should raise_error(ArgumentError)
      end
      
      it "should not allow to be called with any number of invalid attributes as parameters" do
        
        @s.attributes_to_clone = 'foo';            @s.should_not be_valid 
        @s.attributes_to_clone = :foo;             @s.should_not be_valid 
        @s.attributes_to_clone = 'foo, name';      @s.should_not be_valid 
        @s.attributes_to_clone = [ :foo, 'name' ]; @s.should_not be_valid 
        
      end
            
      it "should allow to be called with a String naming one valid attribute" do
        
        @s.attributes_to_clone = "name"
        @s.should be_valid
        
      end
            
      it "should allow to be called with a Symbol naming one valid attribute" do
        
        @s.attributes_to_clone = :name
        @s.should be_valid
        
      end
            
      it "should allow to be called with a String containing a comma separated list of valid attributes" do
        
        @s.attributes_to_clone = "name, description"
        @s.should be_valid
        
      end
            
      it "should allow to be called with an Array containing valid attributes as Symbols or Strings" do
        
        @s.attributes_to_clone = [ 'name', 'description' ]
        @s.should be_valid
        @s.attributes_to_clone = [ :name, :description ]
        @s.should be_valid
        
      end
                  
      it "should allow to be called with another ItemCloneSpec" do
        s = @i.item_clone_specs.create(:name => "test", :attributes_to_clone => [ :name, :description ])
        @s.attributes_to_clone = s
        @s.should be_valid
      end
      
    end
    
    
  end
  
end