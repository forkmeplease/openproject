# frozen_string_literal: true

require "spec_helper"
require "mini_magick"

RSpec.describe "My avatar management", :js do
  include Rails.application.routes.url_helpers

  let(:image_base_path) { File.expand_path("#{File.dirname(__FILE__)}/../fixtures/") }
  let(:user) { create(:user) }
  let(:avatar_management_path) { my_account_path }

  let(:enable_gravatars) { false }
  let(:enable_local_avatars) { false }
  let(:plugin_settings) do
    {
      "enable_gravatars" => enable_gravatars,
      "enable_local_avatars" => enable_local_avatars
    }
  end

  before do
    login_as user
    allow(Setting)
      .to receive(:plugin_openproject_avatars)
      .and_return(plugin_settings)
  end

  describe "only gravatars enabled" do
    let(:enable_gravatars) { true }

    it "shows the Gravatar hint and the current avatar but no upload field" do
      visit avatar_management_path

      expect(page).to have_css(".avatars--current-avatar")
      expect(page).to have_link("gravatar.com")
      expect(page).to have_no_field("avatar_file_input")
    end
  end

  describe "only local avatars enabled" do
    let(:enable_local_avatars) { true }

    it "can upload and delete a custom avatar" do
      visit avatar_management_path
      expect(page).to have_css(".avatars--upload-trigger")

      # Gravatar hint is not rendered
      expect(page).to have_no_link("gravatar.com")

      # Attach a new invalid image
      attach_file("avatar_file_input",
                  UploadedFile.load_from(File.join(image_base_path, "invalid.txt")).path,
                  make_visible: true)

      # Expect error
      expect(page).to have_css(".avatars--error-pane", text: "Allowed formats are jpg, png, gif")

      # Attach a valid image; it is uploaded as soon as it is selected
      visit avatar_management_path
      attach_file("avatar_file_input",
                  UploadedFile.load_from(File.join(image_base_path, "too_big.jpg")).path,
                  make_visible: true)

      # Expect the avatar to be uploaded and resized
      expect(page).to have_test_selector("avatar-delete-link", wait: 20)
      avatar_path = user.local_avatar_attachment.file.path
      content_type = OpenProject::ContentTypeDetector.new(avatar_path).detect
      image = MiniMagick::Image.open(avatar_path)

      expect(image.dimensions).to eq [128, 128]
      expect(content_type).to eq("image/jpeg")

      # Delete the avatar
      accept_alert do
        find_test_selector("avatar-delete-link").click
      end

      expect(page).to have_no_test_selector("avatar-delete-link", wait: 20)
    end
  end

  describe "both gravatars and local avatars enabled" do
    let(:enable_gravatars) { true }
    let(:enable_local_avatars) { true }

    it "renders the Gravatar hint and the upload trigger in a single section" do
      visit avatar_management_path

      expect(page).to have_link("gravatar.com")
      expect(page).to have_css(".avatars--upload-trigger")
    end
  end

  describe "none enabled" do
    before do
      allow(Setting)
        .to receive(:plugin_openproject_avatars)
        .and_return({})
    end

    it "does not render the avatar section on the account page" do
      visit my_account_path

      expect(page).to have_text(I18n.t(:label_my_account))
      expect(page).to have_no_css(".avatars--current-avatar")
    end
  end
end
