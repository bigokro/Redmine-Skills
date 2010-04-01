namespace :skills do
  namespace :db do
    desc 'Migrates the Redmine Skills plugin database.'
    task :migrate => :environment do
      if Rails.respond_to?('plugins')
        Rails.plugins['redmine_skills'].migrate ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      else
        puts "Undefined method plugins for Rails!"
        puts "Make sure engines plugin is installed."
      end
    end
  end
end
