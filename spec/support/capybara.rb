require "timeout"

require "selenium/webdriver"

Capybara.register_driver :headless_chrome do |app|
  # `--disable-dev-shm-usage` keeps Chrome off the small `/dev/shm` of CI
  # runners and containers, where exhausting it crashes the renderer.
  options = Selenium::WebDriver::Chrome::Options.new(
    args: %w[--no-sandbox --headless --disable-dev-shm-usage],
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

RSpec.configure do |config|
  # A crashed browser can leave the driver waiting forever: fail the example
  # with a backtrace instead of eating the job's runtime cap.
  config.around(:each, :js) do |example|
    Timeout.timeout(300) { example.run }
  end
end
