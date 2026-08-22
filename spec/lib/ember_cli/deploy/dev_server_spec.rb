require "ember_cli/deploy/dev_server"

describe EmberCli::Deploy::DevServer do
  describe "#index_html" do
    it "rewrites root-relative URLs to the development server's origin" do
      deploy = build_deploy(index_html: <<~HTML)
        <!DOCTYPE html>
        <html>
          <head>
            <script type="module" src="/@vite/client"></script>
            <link rel="stylesheet" href="/@embroider/virtual/app.css">
          </head>
          <body>
            <script src="/@embroider/virtual/vendor.js"></script>
            <script type="module" src="/index.html?html-proxy&index=0.js"></script>
          </body>
        </html>
      HTML

      index_html = deploy.index_html

      expect(index_html).to include(
        %{src="http://127.0.0.1:4200/@vite/client"},
        %{href="http://127.0.0.1:4200/@embroider/virtual/app.css"},
        %{src="http://127.0.0.1:4200/@embroider/virtual/vendor.js"},
        %{src="http://127.0.0.1:4200/index.html?html-proxy&index=0.js"},
      )
    end

    it "rewrites single-quoted attributes" do
      deploy = build_deploy(index_html: %{<script src='/app/app.js'></script>})

      index_html = deploy.index_html

      expect(index_html).to eq(
        %{<script src='http://127.0.0.1:4200/app/app.js'></script>},
      )
    end

    it "leaves document-relative URLs alone" do
      deploy = build_deploy(index_html: %{<img src="assets/logo.png">})

      index_html = deploy.index_html

      expect(index_html).to eq(%{<img src="assets/logo.png">})
    end

    it "leaves absolute and protocol-relative URLs alone" do
      deploy = build_deploy(index_html: <<~HTML)
        <link rel="stylesheet" href="https://cdn.example.com/app.css">
        <script src="//cdn.example.com/app.js"></script>
      HTML

      index_html = deploy.index_html

      expect(index_html).to include(
        %{href="https://cdn.example.com/app.css"},
        %{src="//cdn.example.com/app.js"},
      )
    end

    it "leaves attributes that merely end in `src` or `href` alone" do
      deploy = build_deploy(index_html: %{<meta data-src="/not-a-url">})

      index_html = deploy.index_html

      expect(index_html).to eq(%{<meta data-src="/not-a-url">})
    end

    it "leaves the encoded configuration meta tag alone" do
      content = "%7B%22rootURL%22%3A%22%2F%22%7D"
      deploy = build_deploy(
        index_html: %{<meta name="my-app/config/environment" content="#{content}" />},
      )

      index_html = deploy.index_html

      expect(index_html).to include(content)
    end

    it "returns a string that can be mutated by `HtmlPage::Renderer`" do
      deploy = build_deploy(index_html: "<html><head></head><body></body></html>")

      index_html = deploy.index_html

      expect { index_html.insert(0, "!") }.not_to raise_error
    end
  end

  describe "#mountable?" do
    it "returns true" do
      deploy = build_deploy(index_html: "")

      mountable = deploy.mountable?

      expect(mountable).to be true
    end
  end

  describe "#to_rack" do
    it "creates a proxy to the development server" do
      deploy = build_deploy(index_html: "")

      rack_app = deploy.to_rack

      expect(rack_app).to be_a(EmberCli::DevServerProxy)
      expect(rack_app).to respond_to(:call)
    end
  end

  def build_deploy(index_html:, origin: "http://127.0.0.1:4200")
    dev_server = double(
      "EmberCli::DevServer",
      index_html: index_html,
      origin: origin,
    )

    EmberCli::Deploy::DevServer.new(double("EmberCli::App", dev_server: dev_server))
  end
end
