
namespace :tessa do
  desc "Begins the migration of all Tessa assets to ActiveStorage."
  task :migrate => :environment do
    Tessa::MigrateAssetsJob.perform_later
  end
end