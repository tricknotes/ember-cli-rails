require "selenium/webdriver"

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new(
    args: %w[--no-sandbox --headless],
  )

  # Point Selenium at a specific Chrome binary, e.g. inside a container
  # without a system-wide Chrome installation.
  if ENV["CHROME_BIN"]
    options.binary = ENV["CHROME_BIN"]
  end

  # Capture the browser console so that failing examples can dump it.
  options.add_option("goog:loggingPrefs", { browser: "ALL" })

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: options,
  )
end

Capybara.server = :webrick
Capybara.javascript_driver = :headless_chrome
