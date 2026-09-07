require "generator_spec"
require "generators/ember/init/init_generator"

describe EmberCli::InitGenerator, type: :generator do
  destination Rails.root.join("tmp", "init_generator_test_output")

  it "generates an initializer that configures an application" do
    prepare_destination

    run_generator

    expect(destination_root).to have_structure {
      directory "config" do
        directory "initializers" do
          file "ember.rb" do
            contains "EmberCli.configure"
            contains "c.app :frontend"
          end
        end
      end
    }
  end
end
