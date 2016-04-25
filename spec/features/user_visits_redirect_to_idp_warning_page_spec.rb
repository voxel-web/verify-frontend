require 'feature_helper'
require 'i18n'

RSpec.describe 'When the user visits the redirect to IDP warning page' do
  let(:originating_ip) { '<PRINCIPAL IP ADDRESS COULD NOT BE DETERMINED>' }
  let(:encrypted_entity_id) { 'an-encrypted-entity-id' }
  let(:location) { '/test-idp-request-endpoint' }
  let(:response) {
    {
      'location' => location,
      'samlRequest' => 'a-saml-request',
      'relayState' => 'a-relay-state',
      'registration' => false
    }
  }
  let(:given_a_session_with_document_evidence) {
    page.set_rack_session(
      selected_idp: { entity_id: 'http://idcorp.com', simple_id: 'stub-idp-one' },
      selected_idp_was_recommended: true,
      selected_evidence: { phone: %w(mobile_phone smart_phone), documents: %w(passport) },
    )
  }
  let(:given_a_session_with_non_recommended_idp) {
    page.set_rack_session(
      selected_idp: { entity_id: 'http://idcorp.com', simple_id: 'stub-idp-one' },
      selected_idp_was_recommended: false,
      selected_evidence: { phone: %w(mobile_phone smart_phone), documents: %w(passport) },
    )
  }
  let(:given_a_session_with_no_document_evidence) {
    page.set_rack_session(
      selected_idp: { entity_id: 'http://idpnodocs.com', simple_id: 'stub-idp-no-docs' },
      selected_idp_was_recommended: true,
      selected_evidence: { phone: %w(mobile_phone smart_phone), documents: [] },
    )
  }

  before(:each) do
    set_session_cookies!
  end

  it 'includes the appropriate feedback source and page title' do
    given_a_session_with_document_evidence
    visit '/redirect-to-idp-warning'

    expect(page).to have_title "You'll now be redirected - GOV.UK Verify - GOV.UK"
    expect_feedback_source_to_be(page, 'REDIRECT_TO_IDP_WARNING_PAGE')
  end

  it 'should show the user an error page if the required parameters are missing' do
    stub_transactions_list
    visit '/redirect-to-idp-warning'

    expect(page).to have_content 'something went wrong'
  end

  it 'goes to "redirect-to-idp" page on submit' do
    stub_federation
    given_a_session_with_document_evidence
    stub_request(:get, api_uri('session/idp-authn-request'))
      .with(query: { 'originatingIp' => originating_ip }).to_return(body: response.to_json)

    visit '/redirect-to-idp-warning'

    click_button 'Continue to IDCorp'

    expect(page).to have_current_path(redirect_to_idp_path)
  end

  it 'includes the recommended text when selection is a recommended idp' do
    given_a_session_with_document_evidence
    visit '/redirect-to-idp-warning'

    expect(page).to have_content 'You’ll now verify your identity on IDCorp’s website.'
    expect(page).to_not have_content 'Additional IDP instructions'
  end

  it 'includes the recommended text when selection is a non recommended idp' do
    given_a_session_with_non_recommended_idp
    visit '/redirect-to-idp-warning'

    expect(page).to have_content 'To be verified with IDCorp, you’ll need:'
    within('#requirements') do
      expect(page).to have_content('a UK passport')
      expect(page).to have_content('a UK photocard driving licence')
    end
  end

  it 'includes specific IDP text when user has no documents' do
    given_a_session_with_no_document_evidence
    visit '/redirect-to-idp-warning'

    expect(page).to have_content 'You’ll now verify your identity on No Docs IDP’s website.'
    expect(page).to have_content 'Additional IDP Instructions'
  end
end
