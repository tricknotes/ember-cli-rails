feature "User views ember app served by its development server", :js do
  before { skip_without_vite_blueprint }

  # A cold development server runs the embroider prebuild and transforms the
  # application's modules on the first load, which can take well over
  # Capybara's default wait time on a busy CI runner.
  around do |example|
    Capybara.using_wait_time(60) { example.run }
  end

  # These examples fail intermittently on CI with an empty page body. Dump
  # what the browser saw, so that a failing run explains why the application
  # did not boot.
  after do |example|
    next unless example.exception

    begin
      warn "Document for #{example.description.inspect}:"
      warn page.html.to_s[0, 4_000]
      warn "Browser console:"
      page.driver.browser.logs.get(:browser).each do |entry|
        warn "  #{entry.level} #{entry.message}"
      end
    rescue StandardError => error
      warn "Failed to dump the browser state: #{error.class}: #{error.message}"
    end
  end

  scenario "the application boots from the development server" do
    visit dev_server_app_path

    expect(page).to have_javascript_rendered_text
    expect(page).to have_csrf_tags
  end

  scenario "the application's assets are loaded from the development server" do
    visit dev_server_app_path

    expect(page).to have_javascript_rendered_text
    expect(page).to have_vite_client
    expect(page).to have_loaded_client_side_asset
  end

  def have_javascript_rendered_text
    have_text("Welcome to Ember")
  end

  def have_csrf_tags
    have_css("meta[name=csrf-param]", visible: false).
      and have_css("meta[name=csrf-token]", visible: false)
  end

  # Rewriting the root-relative URLs in `index.html` is what lets the Vite
  # client open its HMR connection against the development server directly.
  def have_vite_client
    have_css(
      %{script[src="#{dev_server_origin}/@vite/client"]},
      visible: false,
    )
  end

  # The image is referenced relatively by the application's own template, so
  # the browser requests it from Rails, which proxies it to the development
  # server.
  def have_loaded_client_side_asset
    have_css(%{img[src*="logo.png"]}).and satisfy { logo_loaded? }
  end

  def logo_loaded?
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.1 until evaluate_logo_loaded
      true
    end
  rescue Timeout::Error
    false
  end

  def evaluate_logo_loaded
    page.evaluate_script(<<~JS)
      (function() {
        var image = document.querySelector('img[src*="logo.png"]');

        return !!image && image.complete && image.naturalWidth > 0;
      })()
    JS
  end
end
