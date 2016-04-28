require 'rails_helper'

describe 'Filter issues', feature: true do

  let!(:project)   { create(:project) }
  let!(:user)      { create(:user)}
  let!(:milestone) { create(:milestone, project: project) }
  let!(:label)     { create(:label, project: project) }

  before do
    project.team << [user, :master]
    login_as(user)
  end

  describe 'Filter issues for assignee from issues#index' do

    before do
      visit namespace_project_issues_path(project.namespace, project)

      find('.js-assignee-search').click

      find('.dropdown-menu-user-link', text: user.username).click

      sleep 2
    end

    context 'assignee', js: true do
      it 'should update to current user' do
        expect(find('.js-assignee-search .dropdown-toggle-text')).to have_content(user.name)
      end

      it 'should not change when closed link is clicked' do
        find('.issues-state-filters a', text: "Closed").click

        expect(find('.js-assignee-search .dropdown-toggle-text')).to have_content(user.name)
      end


      it 'should not change when all link is clicked' do
        find('.issues-state-filters a', text: "All").click

        expect(find('.js-assignee-search .dropdown-toggle-text')).to have_content(user.name)
      end
    end
  end

  describe 'Filter issues for milestone from issues#index' do

    before do
      visit namespace_project_issues_path(project.namespace, project)

      find('.js-milestone-select').click

      find('.milestone-filter .dropdown-content a', text: milestone.title).click

      sleep 2
    end

    context 'milestone', js: true do
      it 'should update to current milestone' do
        expect(find('.js-milestone-select .dropdown-toggle-text')).to have_content(milestone.title)
      end

      it 'should not change when closed link is clicked' do
        find('.issues-state-filters a', text: "Closed").click

        expect(find('.js-milestone-select .dropdown-toggle-text')).to have_content(milestone.title)
      end


      it 'should not change when all link is clicked' do
        find('.issues-state-filters a', text: "All").click

        expect(find('.js-milestone-select .dropdown-toggle-text')).to have_content(milestone.title)
      end
    end
  end

  describe 'Filter issues for label from issues#index', js: true do
    before do
      visit namespace_project_issues_path(project.namespace, project)
      find('.js-label-select').click
    end

    it 'should filter by any label' do
      find('.dropdown-menu-labels a', text: 'Any Label').click
      page.first('.labels-filter .dropdown-title .dropdown-menu-close-icon').click
      sleep 2

      page.within '.labels-filter' do
        expect(page).to have_content 'Any Label'
      end
      expect(find('.js-label-select .dropdown-toggle-text')).to have_content('Any Label')
    end

    it 'should filter by no label' do
      find('.dropdown-menu-labels a', text: 'No Label').click
      page.first('.labels-filter .dropdown-title .dropdown-menu-close-icon').click
      sleep 2

      page.within '.labels-filter' do
        expect(page).to have_content 'No Label'
      end
      expect(find('.js-label-select .dropdown-toggle-text')).to have_content('No Label')
    end

    it 'should filter by no label' do
      find('.dropdown-menu-labels a', text: label.title).click
      page.within '.labels-filter' do
        expect(page).to have_content label.title
      end
      expect(find('.js-label-select .dropdown-toggle-text')).to have_content(label.title)
    end
  end

  describe 'Filter issues for assignee and label from issues#index' do

    before do
      visit namespace_project_issues_path(project.namespace, project)

      find('.js-assignee-search').click

      find('.dropdown-menu-user-link', text: user.username).click

      sleep 2

      find('.js-label-select').click

      find('.dropdown-menu-labels .dropdown-content a', text: label.title).click
      page.first('.labels-filter .dropdown-title .dropdown-menu-close-icon').click

      sleep 2
    end

    context 'assignee and label', js: true do
      it 'should update to current assignee and label' do
        expect(find('.js-assignee-search .dropdown-toggle-text')).to have_content(user.name)
        expect(find('.js-label-select .dropdown-toggle-text')).to have_content(label.title)
      end

      it 'should not change when closed link is clicked' do
        find('.issues-state-filters a', text: "Closed").click

        expect(find('.js-assignee-search .dropdown-toggle-text')).to have_content(user.name)
        expect(find('.js-label-select .dropdown-toggle-text')).to have_content(label.title)
      end


      it 'should not change when all link is clicked' do
        find('.issues-state-filters a', text: "All").click

        expect(find('.js-assignee-search .dropdown-toggle-text')).to have_content(user.name)
        expect(find('.js-label-select .dropdown-toggle-text')).to have_content(label.title)
      end
    end
  end

  describe 'filter by any author', js: true do
    before do
      user2 = create(:user, name: "tester")
      create(:issue, project: project, author: user)
      create(:issue, project: project, author: user2)

      visit namespace_project_issues_path(project.namespace, project)
    end

    it 'should show filter by any author link' do
      click_button "Author"
      fill_in "Search authors", with: "tester"

      page.within ".dropdown-menu-author" do
        expect(page).to have_content "tester"
      end
    end

    it 'should show filter issues by any author' do
      page.within '.issues-list' do
        expect(page).to have_selector ".issue", count: 2
      end

      click_button "Author"
      fill_in "Search authors", with: "tester"

      page.within ".dropdown-menu-author" do
        click_link "tester"
      end

      page.within '.issues-list' do
        expect(page).to have_selector ".issue", count: 1
      end
    end
  end
end
