require 'spec_helper'

describe 'Projects > Merge requests > User lists merge requests', feature: true do
  include SortingHelper

  let(:project) { create(:project, :public) }
  let(:user) { create(:user) }

  before { login_with(user) }

  describe 'Filter merge requests' do
    before do
      %w[fix markdown].each do |branch|
        create(:merge_request,
               author: user,
               assignee: user,
               source_project: project,
               source_branch: branch,
               title: branch)
      end
      create(:merge_request,
             author: user,
             assignee: nil,
             source_project: project,
             source_branch: 'lfs',
             title: 'lfs',
             milestone: create(:milestone, project: project))
    end

    it 'allows filtering by merge requests with no specified assignee' do
      visit namespace_project_merge_requests_path(project.namespace, project, assignee_id: IssuableFinder::NONE)

      expect(current_path).to eq(namespace_project_merge_requests_path(project.namespace, project))
      expect(page).to have_content 'lfs'
      expect(page).not_to have_content 'fix'
      expect(page).not_to have_content 'markdown'
    end

    it 'allows filtering by a specified assignee' do
      visit namespace_project_merge_requests_path(project.namespace, project, assignee_id: user.id)

      expect(page).not_to have_content 'lfs'
      expect(page).to have_content 'fix'
      expect(page).to have_content 'markdown'
    end
  end

  describe 'Filter & Sort merge requests' do
    %w[fix markdown lfs].each_with_index do |branch, index|
      let!(branch.to_sym) do
        create(:merge_request,
               title: branch,
               source_project: project,
               source_branch: branch,
               created_at: Time.now - (index * 60))
      end
    end
    let(:newer_due_milestone) { create(:milestone, due_date: '2013-12-11') }
    let(:later_due_milestone) { create(:milestone, due_date: '2013-12-12') }

    describe 'Sort merge requests' do
      it 'sorts by newest' do
        visit namespace_project_merge_requests_path(project.namespace, project, sort: sort_value_recently_created)

        expect(first_merge_request).to include('lfs')
        expect(last_merge_request).to include('fix')
      end

      it 'sorts by oldest' do
        visit namespace_project_merge_requests_path(project.namespace, project, sort: sort_value_oldest_created)

        expect(first_merge_request).to include('fix')
        expect(last_merge_request).to include('lfs')
      end

      it 'sorts by most recently updated' do
        lfs.updated_at = Time.now + 100
        lfs.save
        visit namespace_project_merge_requests_path(project.namespace, project, sort: sort_value_recently_updated)

        expect(first_merge_request).to include('lfs')
      end

      it 'sorts by least recently updated' do
        lfs.updated_at = Time.now - 100
        lfs.save
        visit namespace_project_merge_requests_path(project.namespace, project, sort: sort_value_oldest_updated)

        expect(first_merge_request).to include('lfs')
      end

      describe 'sorting by milestone' do
        before do
          fix.milestone = newer_due_milestone
          fix.save
          markdown.milestone = later_due_milestone
          markdown.save
        end

        it 'sorts by recently due milestone' do
          visit namespace_project_merge_requests_path(project.namespace, project, sort: sort_value_milestone_soon)

          expect(first_merge_request).to include('fix')
        end

        it 'sorts by least recently due milestone' do
          visit namespace_project_merge_requests_path(project.namespace, project, sort: sort_value_milestone_later)

          expect(first_merge_request).to include('markdown')
        end
      end
    end

    describe 'Filter and sort at the same time' do
      let(:user2) { create(:user) }

      before do
        fix.assignee = user2
        fix.milestone = newer_due_milestone
        fix.save
        markdown.assignee = user2
        markdown.milestone = later_due_milestone
        markdown.save
      end

      context 'filter on one label' do
        let(:label) { create(:label, project: project) }
        before { create(:label_link, label: label, target: fix) }

        it 'sorts by due soon' do
          visit namespace_project_merge_requests_path(project.namespace, project,
            label_name: [label.name],
            sort: sort_value_due_date_soon)

          expect(first_merge_request).to include('fix')
        end
      end

      context 'filter on two labels' do
        let(:label) { create(:label, project: project) }
        let(:label2) { create(:label, project: project) }
        before do
          create(:label_link, label: label, target: fix)
          create(:label_link, label: label2, target: fix)
        end

        it 'sorts by due soon' do
          visit namespace_project_merge_requests_path(project.namespace, project,
            label_name: [label.name, label2.name],
            sort: sort_value_due_date_soon)

          expect(first_merge_request).to include('fix')
        end

        context 'filter on assignee' do
          it 'sorts by due soon' do
            visit namespace_project_merge_requests_path(project.namespace, project,
              label_name: [label.name, label2.name],
              assignee_id: user2.id,
              sort: sort_value_due_date_soon)

            expect(first_merge_request).to include('fix')
          end

          it 'sorts by recently due milestone' do
            visit namespace_project_merge_requests_path(project.namespace, project,
              label_name: [label.name, label2.name],
              assignee_id: user2.id,
              sort: sort_value_milestone_soon)

            expect(first_merge_request).to include('fix')
          end
        end
      end
    end
  end

  def first_merge_request
    page.all('ul.mr-list > li').first.text
  end

  def last_merge_request
    page.all('ul.mr-list > li').last.text
  end
end
