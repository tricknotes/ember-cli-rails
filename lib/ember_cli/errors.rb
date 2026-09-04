module EmberCli
  class BuildError < StandardError; end
  class DependencyError < BuildError; end
  class TestFailureError < StandardError; end
end
