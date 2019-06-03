# frozen_string_literal: true

require 'spec_helper'

describe 'Change styles', js: true do
  subject do
    # I open the dashboard page
    visit dashboard_path
  end

  let!(:admin_user) do
    FactoryGirl.create(:admin_user, username: username, email: "#{username}@example.com", password: password)
  end

  let(:username) { 'admin1' }
  let(:password) { 'password' }

  def sign_in_as_admin_user!
    visit '/login'
    expect(page).to have_css('div#login')
    within 'div#login' do
      page.find(:css, "input[type='text']").set(username)
      page.find(:css, "input[type='password']").set(password)
      page.find('[type="submit"]').click
    end
  end

  before do
    Capybara.current_session.driver.reset!
  end

  after do
    # Clear any cache left
    Rails.cache.clear
    # Poltergeist black magic to avoid phantomjs to die mid-run
    page.driver.reset!
    # ActionController::Base.allow_rescue = false
  end

  describe 'change_color' do
    before do
      # I open variables.scss file and override variable "$text-color: blue !default;"
      old_themes_path = "#{Rails.root}/app/assets/stylesheets/hidden_themes"
      themes_path = "#{Rails.root}/app/assets/stylesheets/themes"
      File.rename(themes_path, old_themes_path)
      FileUtils.mkdir(themes_path)
      File.open("#{themes_path}/variables.scss", 'w') do |f|
        f.puts '$text-color: blue !default;'
      end

      # I signed in as admin user with username "admin1"
      sign_in_as_admin_user!
    end

    after do
      # Restore app/assets/stylesheets/themes/*
      old_themes_path = "#{Rails.root}/app/assets/stylesheets/hidden_themes"
      themes_path = "#{Rails.root}/app/assets/stylesheets/themes"
      if File.exist?(old_themes_path)
        FileUtils.rm_r(themes_path)
        File.rename(old_themes_path, themes_path)
      end
    end

    it 'The page text should be blue' do
      subject
      expect(page).to have_css('.footer p')
      expect(page.evaluate_script("$('.footer p').css('color')")).to eq 'rgb(0, 0, 255)'
    end
  end

  describe 'change logo src' do
    def reload_initializers!
      load "#{Rails.root}/config/initializers/_config.rb"
      load "#{Rails.root}/config/initializers/active_admin.rb"
    end

    before do
      # When I create yeti_web yml file and add site title "site_title: 'Yeti Admin'"
      # And I add site image src "site_title_image: '/images/logo.png'"
      # And I add role_policy
      # And I add role_policy nested "when_no_config: allow"
      # And I add role_policy nested "when_no_policy_class: raise"
      old_config_path = "#{Rails.root}/config/old_yeti_web.yml"
      config_path = "#{Rails.root}/config/yeti_web.yml"
      File.rename(config_path, old_config_path) if File.exist?(config_path)
      File.open(config_path, 'w') do |file|
        file.puts "site_title: 'Yeti Admin'"
        file.puts "site_title_image: '/images/logo.png'"
        file.puts 'role_policy:'
        file.puts '  when_no_config: allow'
        file.puts '  when_no_policy_class: raise'
      end

      # And Reinitialize YetiWeb
      reload_initializers!

      # I signed in as admin user with username "admin1"
      sign_in_as_admin_user!
    end

    after do
      # Restore config/yeti_web.yml
      old_config_path = "#{Rails.root}/config/old_yeti_web.yml"
      config_path = "#{Rails.root}/config/yeti_web.yml"
      if File.exist?(old_config_path)
        File.delete(config_path)
        File.rename(old_config_path, config_path)
      else
        File.delete(config_path)
      end

      reload_initializers!
    end

    # Then The title image src should be "/images/logo.png"
    it 'The title image src should be /images/logo.png' do
      subject
      expect(page).to have_css('img#site_title_image')
      expect(page.evaluate_script("$('img#site_title_image').attr('src')")).to eq '/images/logo.png'
    end
  end
end
