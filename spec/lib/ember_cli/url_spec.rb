require "ember_cli/url"

describe EmberCli::Url do
  describe ".remote?" do
    it "is true for a URL carrying a scheme" do
      expect(EmberCli::Url).to be_remote("https://cdn.example.com/app.js")
      expect(EmberCli::Url).to be_remote("data:text/css,body{}")
    end

    it "is true for a protocol-relative URL" do
      expect(EmberCli::Url).to be_remote("//cdn.example.com/app.js")
    end

    it "is false for a URL that points into the build" do
      expect(EmberCli::Url).not_to be_remote("/assets/app.js")
      expect(EmberCli::Url).not_to be_remote("assets/app.js")
    end

    it "is false for no URL at all" do
      expect(EmberCli::Url).not_to be_remote(nil)
    end
  end
end
