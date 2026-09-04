describe EmberCli do
  describe ".any?" do
    it "delegates to the collection of applications" do
      stub_apps(
        app_with_foo: { foo: true },
        app_without_foo: { foo: false },
      )

      any_with_foo = EmberCli.any? { |app| app.fetch(:foo) }

      expect(any_with_foo).to be true
    end
  end

  describe ".test!" do
    it "runs every application's test suite" do
      passing = test_app(name: "passing", passed: true)
      also_passing = test_app(name: "also-passing", passed: true)
      stub_apps(passing: passing, also_passing: also_passing)

      EmberCli.test!

      expect(passing).to have_received(:test)
      expect(also_passing).to have_received(:test)
    end

    it "raises when an application's test suite fails" do
      failing = test_app(name: "failing", passed: false)
      stub_apps(failing: failing)

      expect { EmberCli.test! }.to raise_error(
        EmberCli::TestFailureError,
        /"failing"/,
      )
    end

    def test_app(name:, passed:)
      instance_double(EmberCli::App, name: name, test: passed)
    end
  end

  def stub_apps(applications)
    allow(EmberCli).to receive(:apps).and_return(applications)
  end
end
