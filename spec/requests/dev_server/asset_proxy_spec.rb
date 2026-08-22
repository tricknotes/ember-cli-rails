describe "Request an asset from an app served by its development server" do
  before { skip_without_vite_blueprint }

  it "proxies the request to the development server" do
    get "/dev-server/assets/logo.png"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("image/png")
    expect(response.body.bytesize).to eq(logo_size)
  end

  it "forwards the query string" do
    get "/dev-server/assets/logo.png", params: { v: "1" }

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("image/png")
  end

  it "responds to `HEAD` requests without a body" do
    head "/dev-server/assets/logo.png"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("image/png")
    expect(response.body).to be_empty
  end

  it "rejects verbs that the development server does not serve assets for" do
    post "/dev-server/assets/logo.png"

    expect(response).to have_http_status(:method_not_allowed)
    expect(response.headers["allow"]).to eq("GET, HEAD, OPTIONS")
  end

  def logo_size
    Rails.root.join("my-app", "public", "assets", "logo.png").size
  end
end
