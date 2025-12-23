# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# IMPORTANT: Do NOT add Administrator data here!
# Administrator accounts should be created manually by user.
# This seeds file is only for application data (products, categories, etc.)
#
require 'open-uri'

# Create default organization (only if none exists)
if Organization.count.zero?
  # Find or create admin user
  admin_user = User.find_or_create_by!(email: 'admin@example.com') do |user|
    user.name = 'Admin User'
    user.password = 'password123'
    user.verified = true
  end

  org = Organization.create!(
    name: '人脉主页',
    description: '基于黄金圈理念，为每位伙伴构建可在微信生态传播的个人品牌页面',
    admin_user: admin_user
  )

  puts "Created default organization: #{org.name}"
  puts "Invite token: #{org.invite_token}"
  puts "Invite URL: http://localhost:3000/sign_up?invite_token=#{org.invite_token}"
end
