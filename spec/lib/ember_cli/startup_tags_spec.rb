require "ember_cli/startup_tags"

describe EmberCli::StartupTags do
  it "extracts the tags the application boots from" do
    tags = EmberCli::StartupTags.new(<<~HTML).to_a
      <html>
        <head>
          <meta name="my-app/config/environment" content="%7B%7D">
          <link rel="stylesheet" href="/app.css">
          <link rel="modulepreload" href="/vendor.js">
          <link rel="icon" href="/favicon.ico">
          <script type="module" src="/app.js"></script>
        </head>
        <body></body>
      </html>
    HTML

    expect(tags).to match_array([
      %{<meta name="my-app/config/environment" content="%7B%7D">},
      %{<link rel="stylesheet" href="/app.css">},
      %{<link rel="modulepreload" href="/vendor.js">},
      %{<script type="module" src="/app.js"></script>},
    ])
  end

  it "joins the prefix onto root-relative URLs" do
    tags = EmberCli::StartupTags.new(<<~HTML, prefix: "http://127.0.0.1:4200/").to_a
      <html>
        <head>
          <link rel="stylesheet" href="/app.css">
          <script type="module" src="/app.js"></script>
        </head>
      </html>
    HTML

    expect(tags).to include(%{<link rel="stylesheet" href="http://127.0.0.1:4200/app.css">})
    expect(tags).to include(%{<script type="module" src="http://127.0.0.1:4200/app.js"></script>})
  end

  it "leaves absolute and protocol-relative URLs alone" do
    tags = EmberCli::StartupTags.new(<<~HTML, prefix: "/admin").to_a
      <html>
        <head>
          <script src="https://cdn.example.com/analytics.js"></script>
          <script src="//cdn.example.com/protocol-relative.js"></script>
        </head>
      </html>
    HTML

    expect(tags).to match_array([
      %{<script src="https://cdn.example.com/analytics.js"></script>},
      %{<script src="//cdn.example.com/protocol-relative.js"></script>},
    ])
  end
end
