
namespace :tessa do
  desc "Begins the migration of all Tessa assets to ActiveStorage."
  task :migrate => :environment do
    abort "Tessa::MigrateAssetsJob can no longer be performed because the Tessa connection was removed. "\
      "Please downgrade to tessa ~>1.0 and try again."
  end

  desc "Verifies that the migration has completed"
  task :verify => :environment do
    unless Tessa::MigrateAssetsJob.complete?
      state = Tessa::MigrateAssetsJob::ProcessingState.initialize_from_models

      abort "Tessa::MigrateAssetsJob not yet complete!  #{state.count} records remain to be migrated. "\
        "Please downgrade to tessa ~>1.0 and try again."
    end
  end
end