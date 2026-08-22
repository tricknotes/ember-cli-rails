describe "GET a JavaScript asset" do
  it "responds with the 'Cache-Control' header from Rails" do
    build_ember_cli_assets

    get "/assets/#{javascript_asset_name}"

    expect(headers["Cache-Control"]).to eq(cache_for_five_minutes)
  end

  def build_ember_cli_assets
    EmberCli["my-app"].build
  end

  def javascript_asset_name
    assets = EmberCli["my-app"].dist_path.join("assets")

    Pathname.glob(assets.join("*.js")).first.basename
  end

  def cache_for_five_minutes
    Dummy::Application::CACHE_CONTROL_FIVE_MINUTES
  end
end
