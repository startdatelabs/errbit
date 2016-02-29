module ErrbitJiraPlugin
  class IssueTracker < ErrbitPlugin::IssueTracker
    def self.icons
      @icons ||= {
        create: [
          'image/png', ErrbitJiraPlugin.read_static_file('jira_create.png')
        ],
        goto: [
          'image/png', ErrbitJiraPlugin.read_static_file('jira_goto.png'),
        ],
        inactive: [
          'image/png', ErrbitJiraPlugin.read_static_file('jira_inactive.png'),
        ]
      }
    end
  end

  def self.read_static_file(file)
    File.read(File.join(self.root, 'vendor/assets/images', file))
  end
end

require 'errbit_jira_plugin'
