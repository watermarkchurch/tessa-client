
namespace :tessa do
  desc "Begins the migration of all Tessa assets to ActiveStorage."
  task :migrate => :environment do
    Tessa::MigrateAssetsJob.perform_later
  end

  desc "Verifies that the migration has completed"
  task :verify => :environment do
    unless Tessa::MigrateAssetsJob.complete?
      state = Tessa::MigrateAssetsJob::ProcessingState.initialize_from_models

      abort "Tessa::MigrateAssetsJob not yet complete!  #{state.count} records remain to be migrated."
    end
  end
end