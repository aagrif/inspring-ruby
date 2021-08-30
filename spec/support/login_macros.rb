module LoginMacros
  def sign_in_using_form(user)
    visit root_path
    within 'nav#top-menu' do
      click_link 'Sign in'
    end
    within 'form#new_user' do
      fill_in 'Email', with: user.email
      fill_in 'Password', with: user.password
      find('input[name="commit"]').click
    end
  end
end