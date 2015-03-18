require 'spec_helper'

RSpec.describe Tessa::Model::Field do
  subject(:field) { described_class.new(attrs) }
  let(:attrs) { {} }

  describe "#initialize" do
    context "with all fields set" do
      let(:attrs) {
        {
          model: :model,
          name: "name",
          multiple: true,
          id_field: "my_field",
        }
      }

      it "sets :model to attribute" do
        expect(field.model).to eq(:model)
      end

      it "sets :name to attribute" do
        expect(field.name).to eq("name")
      end

      it "sets :multiple to attribute" do
        expect(field.multiple).to eq(true)
      end

      it "sets :id_field to attribute" do
        expect(field.id_field).to eq("my_field")
      end
    end

    context "with no fields set" do
      it "defaults model to nil" do
        expect(field.model).to be_nil
      end

      it "defaults name to nil" do
        expect(field.name).to be_nil
      end

      it "defaults multiple to false" do
        expect(field.multiple).to eq(false)
      end

      context "when multiple true" do
        before do
          attrs[:name] = "my_name"
          attrs[:multiple] = false
        end

        it "defaults id_field to name + '_id'" do
          expect(field.id_field).to eq("my_name_id")
        end
      end

      context "when multiple false" do
        before do
          attrs[:name] = "my_name"
          attrs[:multiple] = true
        end

        it "defaults id_field to name + '_ids'" do
          expect(field.id_field).to eq("my_name_ids")
        end
      end
    end
  end

end
