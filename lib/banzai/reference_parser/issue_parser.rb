module Banzai
  module ReferenceParser
    class IssueParser < Parser
      self.reference_type = :issue

      def user_can_see_reference?(user, node)
        issue = Issue.find_by(id: node.attr('data-issue'))

        Ability.abilities.allowed?(user, :read_issue, issue)
      end

      def referenced_by(nodes)
        ids = nodes.map { |node| node.attr('data-issue') }

        Issue.where(id: ids)
      end
    end
  end
end
