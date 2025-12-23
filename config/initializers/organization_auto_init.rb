# Auto-initialize organization on application startup
# This ensures the organization exists before any requests are processed

Rails.application.config.after_initialize do
  # Only run in non-test environments after database is ready
  next if Rails.env.test?
  
  # Wait for database to be ready (important for production)
  begin
    ActiveRecord::Base.connection.verify!
    
    # Auto-create organization if it doesn't exist
    if Organization.count.zero?
      org = Organization.create!(
        name: '人脉主页',
        description: '基于黄金圈理念，为每位伙伴构建可在微信生态传播的个人品牌页面'
      )
      
      Rails.logger.info "✓ Organization auto-initialized: #{org.name} (ID: #{org.id})"
      Rails.logger.info "  Invite Token: #{org.invite_token}"
    end
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
    # Database not ready or migrations not run yet, skip initialization
    Rails.logger.warn "⚠ Organization auto-initialization skipped: Database not ready"
  rescue => e
    # Log error but don't crash the application
    Rails.logger.error "✗ Organization auto-initialization failed: #{e.message}"
  end
end
