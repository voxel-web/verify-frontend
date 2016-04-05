require 'feature_helper'

RSpec.describe 'When the user visits the select phone page' do
  before(:each) do
    set_session_cookies!
  end

  it 'includes the appropriate feedback source' do
    visit '/select-phone'

    expect_feedback_source_to_be(page, 'SELECT_PHONE_PAGE')
  end

  it 'displays the page in Welsh', pending: true do
    visit '/dethol-ffon'
    expect(page).to have_title 'A oes gennych ffôn symudol neu dabled? - GOV.UK Verify - GOV.UK'
    expect(page).to have_css 'html[lang=cy]'
  end

  context 'with javascript turned off', js: false do
    it 'shows an error message when no selections are made' do
      visit '/select-phone'
      click_button 'Continue'

      expect(page).to have_css '.validation-message', text: 'Please answer the question'
      expect(page).to have_css '.form-group.error'
    end
  end
end