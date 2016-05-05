module Gitlab
  module ImportExport
    class RepoRestorer
      include Gitlab::ImportExport::CommandLineUtil

      def initialize(project:, path_to_bundle:)
        @project = project
        @path_to_bundle = path_to_bundle
      end

      def restore
        return true unless File.exists?(@path_to_bundle)

        FileUtils.mkdir_p(repos_path)
        FileUtils.mkdir_p(path_to_repo)

        git_unbundle(repo_path: path_to_repo, bundle_path: @path_to_bundle)
      rescue
        false
      end

      private

      def repos_path
        Gitlab.config.gitlab_shell.repos_path
      end

      def path_to_repo
        @project.repository.path_to_repo
      end
    end
  end
end