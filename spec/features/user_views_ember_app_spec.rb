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
