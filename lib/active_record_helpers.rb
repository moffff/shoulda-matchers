class Test # :nodoc:
  class Unit # :nodoc:
    class TestCase
      class << self
        # Ensures that the model cannot be saved if one of the attributes listed is not present.
        # Requires an existing record
        def should_require_attributes(*attributes)
          klass = self.name.gsub(/Test$/, '').constantize
          attributes.each do |attribute|
            should "require #{attribute} to be set" do
              object = klass.new
              assert !object.valid?, "Instance is still valid"
              assert object.errors.on(attribute), "No errors found"
              assert object.errors.on(attribute).to_a.include?("can't be blank"), "Error message doesn't match"
            end
          end
        end

        # Ensures that the model cannot be saved if one of the attributes listed is not unique.
        # Requires an existing record
        def should_require_unique_attributes(*attributes)
          klass = self.name.gsub(/Test$/, '').constantize
          attributes.each do |attribute|
            attribute = attribute.to_sym
            should "require unique value for #{attribute}" do
              assert existing = klass.find(:first), "Can't find first #{klass}"
              object = klass.new
              object.send(:"#{attribute}=", existing.send(attribute))
              assert !object.valid?, "Instance is still valid"
              assert object.errors.on(attribute), "No errors found"
              assert object.errors.on(attribute).to_a.include?('has already been taken'), "Error message doesn't match"
            end
          end
        end
  
        # Ensures that the attribute cannot be set on update
        # Requires an existing record
        def should_protect_attributes(*attributes)
          klass = self.name.gsub(/Test$/, '').constantize
          attributes.each do |attribute|
            attribute = attribute.to_sym
            should "not allow #{attribute} to be changed by update" do
              assert object = klass.find(:first), "Can't find first #{klass}"
              value = object[attribute]
              assert object.update_attributes({ attribute => 1 }), 
                     "Cannot update #{klass} with { :#{attribute} => 1 }, #{object.errors.full_messages.to_sentence}"
              assert object.valid?, "#{klass} isn't valid after changing #{attribute}"
              assert_equal value, object[attribute], "Was able to change #{klass}##{attribute}"
            end
          end
        end
    
        # Ensures that the attribute cannot be set to the given values
        # Requires an existing record
        def should_not_allow_values_for(attribute, *bad_values)
          klass = self.name.gsub(/Test$/, '').constantize
          bad_values.each do |v|
            should "not allow #{attribute} to be set to \"#{v}\"" do
              assert object = klass.find(:first), "Can't find first #{klass}"
              object.send("#{attribute}=", v)
              assert !object.save, "Saved #{klass} with #{attribute} set to \"#{v}\""
              assert object.errors.on(attribute), "There are no errors set on #{attribute} after being set to \"#{v}\""
              assert_match(/invalid/, object.errors.on(attribute), "Error set on #{attribute} doesn't include \"invalid\" when set to \"#{v}\"")
            end
          end
        end
    
        # Ensures that the attribute can be set to the given values.
        # Requires an existing record
        def should_allow_values_for(attribute, *good_values)
          klass = self.name.gsub(/Test$/, '').constantize
          good_values.each do |v|
            should "allow #{attribute} to be set to \"#{v}\"" do
              assert object = klass.find(:first), "Can't find first #{klass}"
              object.send("#{attribute}=", v)
              object.save
              # assert object.errors.on(attribute), "There are no errors set on #{attribute} after being set to \"#{v}\""
              assert_no_match(/invalid/, object.errors.on(attribute), "Error set on #{attribute} includes \"invalid\" when set to \"#{v}\"")
            end
          end
        end

        # Ensures that the length of the attribute is in the given range
        # Requires an existing record
        def should_ensure_length_in_range(attribute, range)
          klass = self.name.gsub(/Test$/, '').constantize
          min_length = range.first
          max_length = range.last

          min_value = "x" * (min_length - 1)
          max_value = "x" * (max_length + 1)

          should "not allow #{attribute} to be less than #{min_length} chars long" do
            assert object = klass.find(:first), "Can't find first #{klass}"
            object.send("#{attribute}=", min_value)
            assert !object.save, "Saved #{klass} with #{attribute} set to \"#{min_value}\""
            assert object.errors.on(attribute), "There are no errors set on #{attribute} after being set to \"#{min_value}\""
            assert_match(/short/, object.errors.on(attribute), "Error set on #{attribute} doesn't include \"short\" when set to \"#{min_value}\"")
          end
      
          should "not allow #{attribute} to be more than #{max_length} chars long" do
            assert object = klass.find(:first), "Can't find first #{klass}"
            object.send("#{attribute}=", max_value)
            assert !object.save, "Saved #{klass} with #{attribute} set to \"#{max_value}\""
            assert object.errors.on(attribute), "There are no errors set on #{attribute} after being set to \"#{max_value}\""
            assert_match(/long/, object.errors.on(attribute), "Error set on #{attribute} doesn't include \"long\" when set to \"#{max_value}\"")
          end
        end    

        # Ensure that the attribute is in the range specified
        # Requires an existing record
        def should_ensure_value_in_range(attribute, range)
          klass = self.name.gsub(/Test$/, '').constantize
          min = range.first
          max = range.last

          should "not allow #{attribute} to be less than #{min}" do
            v = min - 1
            assert object = klass.find(:first), "Can't find first #{klass}"
            object.send("#{attribute}=", v)
            assert !object.save, "Saved #{klass} with #{attribute} set to \"#{v}\""
            assert object.errors.on(attribute), "There are no errors set on #{attribute} after being set to \"#{v}\""
          end
      
          should "not allow #{attribute} to be more than #{max}" do
            v = max + 1
            assert object = klass.find(:first), "Can't find first #{klass}"
            object.send("#{attribute}=", v)
            assert !object.save, "Saved #{klass} with #{attribute} set to \"#{v}\""
            assert object.errors.on(attribute), "There are no errors set on #{attribute} after being set to \"#{v}\""
          end
        end    
        
        # Ensure that the attribute is numeric
        # Requires an existing record
        def should_only_allow_numeric_values_for(*attributes)
          klass = self.name.gsub(/Test$/, '').constantize
          attributes.each do |attribute|
            attribute = attribute.to_sym
            should "only allow numeric values for #{attribute}" do
              assert object = klass.find(:first), "Can't find first #{klass}"
              object.send(:"#{attribute}=", "abcd")
              assert !object.valid?, "Instance is still valid"
              assert object.errors.on(attribute), "No errors found"
              assert object.errors.on(attribute).to_a.include?('is not a number'), "Error message doesn't match"
            end
          end
        end

        # Ensures that the has_many relationship exists.
        # The last parameter may be a hash of options.  Currently, the only supported option
        # is :through
        def should_have_many(*associations)
          opts = associations.last.is_a?(Hash) ? associations.pop : {}
          klass = self.name.gsub(/Test$/, '').constantize
          associations.each do |association|
            should "have many #{association}#{" through #{opts[:through]}" if opts[:through]}" do
              reflection = klass.reflect_on_association(association)
              assert reflection
              assert_equal :has_many, reflection.macro
              assert_equal(opts[:through], reflection.options[:through]) if opts[:through]
            end
          end
        end

        # Ensures that the has_and_belongs_to_many relationship exists.  
        def should_have_and_belong_to_many(*associations)
          klass = self.name.gsub(/Test$/, '').constantize
          associations.each do |association|
            should "should have and belong to many #{association}" do
              assert klass.reflect_on_association(association)
              assert_equal :has_and_belongs_to_many, klass.reflect_on_association(association).macro
            end
          end
        end
    
        # Ensure that the has_one relationship exists.
        def should_have_one(*associations)
          klass = self.name.gsub(/Test$/, '').constantize
          associations.each do |association|
            should "have one #{association}" do
              assert klass.reflect_on_association(association)
              assert_equal :has_one, klass.reflect_on_association(association).macro
            end
          end
        end
    
        # Ensure that the belongs_to relationship exists.
        def should_belong_to(*associations)
          klass = self.name.gsub(/Test$/, '').constantize
          associations.each do |association|
            should "belong_to #{association}" do
              assert klass.reflect_on_association(association)
              assert_equal :belongs_to, klass.reflect_on_association(association).macro
            end
          end
        end
      end
    end
  end
end