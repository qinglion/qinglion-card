namespace :organization do
  desc "Initialize organization (creates if not exists)"
  task init: :environment do
    org = Organization.first_or_create!(
      name: '默认组织',
      description: '系统默认组织'
    )
    
    puts "Organization initialized:"
    puts "  ID: #{org.id}"
    puts "  Name: #{org.name}"
    puts "  Description: #{org.description}"
    puts "  Admin User: #{org.admin_user&.email || 'Not set'}"
    puts "  Invite Token: #{org.invite_token}"
  end

  desc "Show organization details"
  task show: :environment do
    org = Organization.first
    
    if org
      puts "Organization details:"
      puts "  ID: #{org.id}"
      puts "  Name: #{org.name}"
      puts "  Description: #{org.description}"
      puts "  Admin User: #{org.admin_user&.email || 'Not set'}"
      puts "  Invite Token: #{org.invite_token}"
      puts "  Members: #{org.profiles.count}"
      puts "    - Approved: #{org.approved_profiles.count}"
      puts "    - Pending: #{org.pending_profiles.count}"
      puts "    - Rejected: #{org.rejected_profiles.count}"
    else
      puts "No organization found. Run 'rake organization:init' to create one."
    end
  end

  desc "Set admin user for organization"
  task :set_admin, [:email] => :environment do |t, args|
    unless args[:email]
      puts "Usage: rake organization:set_admin[user@example.com]"
      exit 1
    end

    org = Organization.first
    unless org
      puts "No organization found. Run 'rake organization:init' first."
      exit 1
    end

    user = User.find_by(email: args[:email])
    unless user
      puts "User with email '#{args[:email]}' not found."
      exit 1
    end

    org.update!(admin_user: user)
    puts "Successfully set #{user.email} as organization admin."
  end
end
