describe "GET a page that renders the Ember app outside of `mount_ember_app`" do
  it "ignores a mount point named by the request" do
    stub_vite_build <<~HTML
      <html><head>
      <script type="module" src="/assets/app.js"></script>
      <link rel="stylesheet" href="/assets/app.css">
      </head><body></body></html>
    HTML

    get "/outside-the-mount", params: { ember_mount_point: "//attacker.example" }

    expect(response.body).to include(%{src="/assets/app.js"})
    expect(response.body).to include(%{href="/assets/app.css"})
    expect(response.body).not_to include("attacker.example")
  end

  def stub_vite_build(index_html)
    app = EmberCli["my-app"]

    allow(app).to receive(:build)
    allow(app.paths).to receive(:vite?).and_return(true)
    allow(app).to receive(:deploy).and_return(double(index_html: index_html))
  end
end
