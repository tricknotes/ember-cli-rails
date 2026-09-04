feature "User views ember app", :js do
  scenario "using route helper" do
    visit default_path

    expect(page).to have_client_side_asset
    expect(page).to have_javascript_rendered_text
    expect(page).to have_csrf_tags
  end

  context "using custom controller" do
    scenario "rendering with asset helpers" do
      visit embedded_path

      expect(page).to have_client_side_asset
      expect(page).to have_javascript_rendered_text
      expect(page).to have_no_csrf_tags
    end

    scenario "rendering with index helper" do
      visit include_index_path

      expect(page).to have_javascript_rendered_text
      expect(page).to have_no_csrf_tags

      visit include_index_empty_block_path

      expect(page).to have_javascript_rendered_text
      expect(page).to have_csrf_tags

      visit include_index_head_and_body_path

      expect(page).to have_javascript_rendered_text
      expect(page).to have_csrf_tags
      expect(page).to have_rails_injected_text
    end
  end

  # `render_ember_app` emits the application's complete HTML document, so the
  # rendering action must disable its layout — the dummy application uses
  # `HighVoltage.layout = false` — or the document ends up nested inside the
  # layout's `<body>`.
  scenario "renders a single, complete HTML document", js: false do
    [include_index_path, include_index_head_and_body_path, default_path].each do |path|
      visit path

      expect(page.html.scan(/<!DOCTYPE/i).count).to eq(1)
      expect(page.html.scan(/<html/i).count).to eq(1)
      expect(page.html).not_to include("<title>Dummy</title>")
    end
  end

  scenario "is redirected with trailing slash", js: false do
    expect(include_index_path).to eq("/no-block")

    visit include_index_path

    expect(current_path).to eq("/no-block/")
  end

  scenario "is redirected with trailing slash with query params", js: false do
    expect(include_index_path(query: "foo")).to eq("/no-block?query=foo")

    visit include_index_path(query: "foo")

    expect(page).to have_current_path("/no-block/?query=foo")
  end

  scenario "is not redirected with trailing slash with params", js: false do
    expect(include_index_path(query: "foo")).to eq("/no-block?query=foo")

    visit "/no-block/?query=foo"

    expect(page).to have_current_path("/no-block/?query=foo")
  end

  def have_client_side_asset
    have_css %{img[src*="logo.png"]}
  end

  def have_rails_injected_text
    have_text "Hello from Rails"
  end

  def have_javascript_rendered_text
    have_text("Welcome to Ember")
  end

  def have_no_csrf_tags
    have_no_css("meta[name=csrf-param]", visible: false).
      and have_no_css("meta[name=csrf-token]", visible: false)
  end

  def have_csrf_tags
    have_css("meta[name=csrf-param]", visible: false).
      and have_css("meta[name=csrf-token]", visible: false)
  end
end
