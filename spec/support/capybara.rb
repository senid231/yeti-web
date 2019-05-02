# frozen_string_literal: true

require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'selenium-webdriver'

Capybara.register_driver(:headless_chrome) do |app|
  options = Selenium::WebDriver::Chrome::Options.new(
    args: %w[headless disable-gpu no-sandbox]
  )
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara::Screenshot.register_driver(:headless_chrome) do |driver, path|
  driver.browser.save_screenshot(path)
end

Capybara::Screenshot.prune_strategy = :keep_last_run
Capybara.server = :webrick
Capybara.default_driver = :rack_test
Capybara.javascript_driver = :headless_chrome

RSpec.configure do |config|
  config.after(type: :feature, js: true) do
    if Capybara.current_driver == :headless_chrome
      STDERR.puts page.driver.browser.manage.logs.get(:browser)
    end
  end
end
